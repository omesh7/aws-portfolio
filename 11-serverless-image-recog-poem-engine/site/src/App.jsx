import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Upload, Image as ImageIcon, Sparkles, FileText, CheckCircle, AlertCircle } from 'lucide-react'
import ImageUploader from './components/ImageUploader'
import ProgressTracker from './components/ProgressTracker'
import PoemDisplay from './components/PoemDisplay'

const UPLOADS_API_URL = import.meta.env.VITE_UPLOADS_API_URL
const GET_POEM_API_URL = import.meta.env.VITE_GET_POEM_API_URL



function App() {
  const [currentStep, setCurrentStep] = useState(0)
  const [uploadedImage, setUploadedImage] = useState(null)
  const [poem, setPoem] = useState('')
  const [labels, setLabels] = useState([])
  const [error, setError] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)
  const [cancelProcessing, setCancelProcessing] = useState(false)

  // Check if environment variables are missing
  if (!UPLOADS_API_URL || !GET_POEM_API_URL) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="max-w-md mx-auto text-center">
          <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h1 className="text-2xl font-bold text-gray-800 mb-2">Configuration Error</h1>
          <p className="text-red-600 mb-4">
            Missing environment variables. Please check your .env file.
          </p>
          
        </div>
      </div>
    )
  }

  const steps = [
    { icon: Upload, label: 'Upload Image', description: 'Choose a beautiful image' },
    { icon: ImageIcon, label: 'Processing', description: 'AI analyzing your image' },
    { icon: Sparkles, label: 'Creating Poetry', description: 'Generating beautiful poem' },
    { icon: FileText, label: 'Complete', description: 'Your poem is ready!' }
  ]

  const handleImageUpload = async (file) => {
    try {
      setError('')
      setCurrentStep(1)
      setIsProcessing(true)
      setCancelProcessing(false)
      setUploadedImage(URL.createObjectURL(file))

      // Get presigned URL
      console.log('Calling upload API:', UPLOADS_API_URL)
      const response = await fetch(UPLOADS_API_URL, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ fileName: file.name })
      })

      console.log('Upload API response:', response.status, response.statusText)
      
      if (!response.ok) {
        const errorText = await response.text()
        console.error('Upload API error:', {
          status: response.status,
          statusText: response.statusText,
          headers: Object.fromEntries(response.headers.entries()),
          body: errorText
        })
        throw new Error(`API Error ${response.status}: ${errorText || response.statusText}`)
      }

      const { uploadUrl, fields, key, poemId } = await response.json()

      // Upload to S3
      const formData = new FormData()
      Object.entries(fields).forEach(([k, v]) => formData.append(k, v))
      formData.append('file', file)

      const uploadResponse = await fetch(uploadUrl, {
        method: 'POST',
        body: formData
      })

      if (!uploadResponse.ok) throw new Error('Upload failed')

      setCurrentStep(2)

      // Start polling for poem result
      pollForPoem(poemId)

    } catch (err) {
      setError(err.message)
      setCurrentStep(0)
      setIsProcessing(false)
    }
  }

  const pollForPoem = async (poemId) => {
    const maxAttempts = 20 // 20 polling attempts max
    let attempts = 0

    // Wait 8 seconds first (processing usually takes 8-12 seconds)
    console.log('Waiting 8 seconds for processing to complete...')
    
    // Wait with cancellation support
    for (let i = 0; i < 80; i++) { // 8 seconds = 80 * 100ms
      if (cancelProcessing) {
        console.log('Processing cancelled by user')
        return
      }
      await new Promise(resolve => setTimeout(resolve, 100))
    }

    const poll = async () => {
      try {
        attempts++
        console.log(`Polling attempt ${attempts} for poemId: ${poemId}`)
        const response = await fetch(`${GET_POEM_API_URL}?poemId=${poemId}`)
        const data = await response.json()
        console.log('Poll response:', { status: response.status, data })

        if (response.ok && data.status === 'completed') {
          setLabels(data.labels || [])
          setPoem(data.poem || 'No poem generated')
          setCurrentStep(3)
          setIsProcessing(false)
          return
        }

        // Handle error responses
        if (!response.ok && response.status !== 404) {
          throw new Error(`Server error: ${data.error || 'Unknown error'}`)
        }

        if (cancelProcessing) {
          console.log('Polling cancelled by user')
          return
        }
        
        if (attempts < maxAttempts) {
          setTimeout(poll, 1000) // Poll every second
        } else {
          throw new Error('Timeout waiting for poem generation')
        }
      } catch (err) {
        if (!cancelProcessing) {
          setError(err.message)
          setCurrentStep(0)
        }
        setIsProcessing(false)
      }
    }

    poll()
  }

  const resetApp = () => {
    setCurrentStep(0)
    setUploadedImage(null)
    setPoem('')
    setLabels([])
    setError('')
    setIsProcessing(false)
    setCancelProcessing(false)
  }

  const stopProcessing = () => {
    setCancelProcessing(true)
    setIsProcessing(false)
    setCurrentStep(0)
    setError('Processing stopped by user')
  }

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-8"
        >
          <h1 className="text-4xl md:text-6xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent mb-4">
            AI Poetry Generator
          </h1>
          <p className="text-gray-600 text-lg">
            Transform your images into beautiful poetry with the power of AI
          </p>
        </motion.div>

        {/* Progress Tracker */}
        <ProgressTracker steps={steps} currentStep={currentStep} />

        {/* Main Content */}
        <div className="mt-8">
          <AnimatePresence mode="wait">
            {error && (
              <motion.div
                key="error"
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className="glass-effect rounded-2xl p-6 mb-6 border-red-200 bg-red-50/80"
              >
                <div className="flex items-center gap-3 text-red-700">
                  <AlertCircle className="w-5 h-5" />
                  <span>{error}</span>
                </div>
              </motion.div>
            )}

            {currentStep === 0 && (
              <ImageUploader key="uploader" onUpload={handleImageUpload} />
            )}

            {currentStep > 0 && currentStep < 3 && (
              <motion.div
                key="processing"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="glass-effect rounded-2xl p-8 text-center"
              >
                {uploadedImage && (
                  <div className="mb-6">
                    <img
                      src={uploadedImage}
                      alt="Uploaded"
                      className="w-48 h-48 object-cover rounded-xl mx-auto shadow-lg"
                    />
                  </div>
                )}

                <div className="flex justify-center mb-4">
                  <div className="w-16 h-16 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin"></div>
                </div>

                <h3 className="text-xl font-semibold text-gray-800 mb-2">
                  {steps[currentStep].description}
                </h3>
                <p className="text-gray-600 mb-4">
                  {currentStep === 1 && "Our AI is analyzing the visual elements in your image..."}
                  {currentStep === 2 && "Creating a beautiful poem inspired by what we found..."}
                </p>
                
                {isProcessing && (
                  <button
                    onClick={stopProcessing}
                    className="px-6 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors duration-200 flex items-center gap-2 mx-auto"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    Stop Processing
                  </button>
                )}
              </motion.div>
            )}

            {currentStep === 3 && (
              <PoemDisplay
                key="result"
                poem={poem}
                labels={labels}
                image={uploadedImage}
                onReset={resetApp}
              />
            )}
          </AnimatePresence>
        </div>
      </div>
    </div>
  )
}

export default App