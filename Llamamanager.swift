import Foundation
import Combine
import llama

/// Real LlamaManager using llama.cpp xcframework
class LlamaManager: ObservableObject {
    
    static let shared = LlamaManager()
    
    @Published var isModelLoaded = false
    @Published var isGenerating = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingStatus: String = ""
    @Published var lastError: String?
    
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var sampler: UnsafeMutablePointer<llama_sampler>?
    private var modelPath: String?
    
    let modelName = "Llama 3.2 1B Instruct"
    let modelVersion = "Q4_K_M"
    let modelSize = "~750 MB"
    
    private init() {
        llama_backend_init()
        findModelFile()
    }
    
    deinit {
        unloadModel()
        llama_backend_free()
    }
    
    // MARK: - Find Model
    
    private func findModelFile() {
        let searchNames = [
            "llama3-health-coach",
            "Llama-3.2-1B-Instruct-Q4_K_M",
            "llama-3.2-1b-instruct"
        ]
        
        for name in searchNames {
            if let path = Bundle.main.path(forResource: name, ofType: "gguf") {
                modelPath = path
                print("✅ Found model: \(name).gguf")
                return
            }
        }
        print("⚠️ No model file found in bundle")
    }
    
    // MARK: - Load Model
    
    func loadModelIfNeeded() async {
        guard !isModelLoaded, model == nil else { return }
        guard let path = modelPath else {
            await MainActor.run {
                lastError = "Model file not found. Add .gguf to Xcode project."
            }
            return
        }
        
        await MainActor.run {
            loadingStatus = "Loading model..."
            loadingProgress = 0.2
        }
        
        // Load on background thread
        let loadedModel = await Task.detached(priority: .userInitiated) { [path] in
            var params = llama_model_default_params()
            params.n_gpu_layers = 99 // Use Metal GPU
            return llama_load_model_from_file(path, params)
        }.value
        
        guard let loadedModel = loadedModel else {
            await MainActor.run {
                lastError = "Failed to load model"
                loadingProgress = 0
            }
            return
        }
        
        self.model = loadedModel
        
        await MainActor.run {
            loadingStatus = "Creating context..."
            loadingProgress = 0.7
        }
        
        // Create context
        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = 2048
        ctxParams.n_batch = 512
        ctxParams.n_threads = 4
        ctxParams.n_threads_batch = 4
        
        guard let ctx = llama_new_context_with_model(loadedModel, ctxParams) else {
            await MainActor.run {
                lastError = "Failed to create context"
            }
            return
        }
        
        self.context = ctx
        
        // Create sampler chain
        let samplerParams = llama_sampler_chain_default_params()
        let samplerChain = llama_sampler_chain_init(samplerParams)
        llama_sampler_chain_add(samplerChain, llama_sampler_init_top_k(40))
        llama_sampler_chain_add(samplerChain, llama_sampler_init_top_p(0.9, 1))
        llama_sampler_chain_add(samplerChain, llama_sampler_init_temp(0.7))
        llama_sampler_chain_add(samplerChain, llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)))
        self.sampler = samplerChain
        
        await MainActor.run {
            loadingStatus = "Ready!"
            loadingProgress = 1.0
            isModelLoaded = true
        }
        
        print("✅ Model loaded with Metal acceleration!")
    }
    
    // MARK: - Generate Response
    
    func generateResponse(prompt: String, healthContext: String) async -> String {
        if !isModelLoaded {
            await loadModelIfNeeded()
            if !isModelLoaded {
                return "Model loading... please wait and try again."
            }
        }
        
        guard let model = model, let context = context, let sampler = sampler else {
            return "Model not available"
        }
        
        await MainActor.run {
            isGenerating = true
        }
        
        defer {
            Task { @MainActor in
                isGenerating = false
            }
        }
        
        // Build prompt with Llama 3.2 chat format
        let systemPrompt = """
        You are a helpful AI health coach. You have access to the user's health data. Give personalized, actionable advice based on their metrics. Be warm, encouraging, and concise.
        
        USER'S HEALTH DATA:
        \(healthContext)
        """
        
        let fullPrompt = """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        \(systemPrompt)<|eot_id|><|start_header_id|>user<|end_header_id|>
        \(prompt)<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        """
        
        // Tokenize
        let tokens = tokenize(text: fullPrompt, model: model)
        guard !tokens.isEmpty else {
            return "Failed to process input"
        }
        
        // Process prompt tokens in a batch
        var batch = llama_batch_init(512, 0, 1)
        defer { llama_batch_free(batch) }
        
        for (i, token) in tokens.enumerated() {
            llama_batch_add(&batch, token, Int32(i), [0], i == tokens.count - 1)
        }
        
        if llama_decode(context, batch) != 0 {
            return "Failed to process prompt"
        }
        
        // Generate response
        var response = ""
        var nCur = tokens.count
        let maxTokens = 256
        
        // Reset sampler
        llama_sampler_reset(sampler)
        
        while nCur < tokens.count + maxTokens {
            // Sample next token
            let newToken = llama_sampler_sample(sampler, context, -1)
            
            // Accept the token
            llama_sampler_accept(sampler, newToken)
            
            // Check for end of generation
            if llama_token_is_eog(model, newToken) {
                break
            }
            
            // Convert token to text
            let piece = tokenToPiece(token: newToken, model: model)
            response += piece
            
            // Prepare next batch
            llama_batch_clear(&batch)
            llama_batch_add(&batch, newToken, Int32(nCur), [0], true)
            
            if llama_decode(context, batch) != 0 {
                break
            }
            
            nCur += 1
        }
        
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Tokenization
    
    private func tokenize(text: String, model: OpaquePointer) -> [llama_token] {
        let utf8Count = text.utf8.count
        let nTokens = utf8Count + 1
        var tokens = [llama_token](repeating: 0, count: nTokens)
        
        let n = llama_tokenize(model, text, Int32(utf8Count), &tokens, Int32(nTokens), true, true)
        
        if n < 0 {
            return []
        }
        
        return Array(tokens.prefix(Int(n)))
    }
    
    private func tokenToPiece(token: llama_token, model: OpaquePointer) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        let n = llama_token_to_piece(model, token, &buffer, 256, 0, true)
        
        if n > 0 {
            buffer[Int(n)] = 0
            return String(cString: buffer)
        }
        return ""
    }
    
    // MARK: - Model Info
    
    func getModelInfo() -> ModelInfo {
        return ModelInfo(
            name: modelName,
            quantization: modelVersion,
            size: modelSize,
            isLoaded: isModelLoaded,
            processingMode: "100% On-Device",
            privacyMode: "Data never leaves device"
        )
    }
    
    // MARK: - Cleanup
    
    func unloadModel() {
        if let s = sampler {
            llama_sampler_free(s)
            sampler = nil
        }
        if let ctx = context {
            llama_free(ctx)
            context = nil
        }
        if let mdl = model {
            llama_free_model(mdl)
            model = nil
        }
        isModelLoaded = false
        loadingProgress = 0
    }
}

// MARK: - Model Info Struct

struct ModelInfo {
    let name: String
    let quantization: String
    let size: String
    let isLoaded: Bool
    let processingMode: String
    let privacyMode: String
}

// MARK: - Batch Helpers

func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}

func llama_batch_add(_ batch: inout llama_batch, _ token: llama_token, _ pos: Int32, _ seqIds: [Int32], _ logits: Bool) {
    let i = Int(batch.n_tokens)
    batch.token[i] = token
    batch.pos[i] = pos
    batch.n_seq_id[i] = Int32(seqIds.count)
    for (j, seqId) in seqIds.enumerated() {
        batch.seq_id[i]![j] = seqId
    }
    batch.logits[i] = logits ? 1 : 0
    batch.n_tokens += 1
}
