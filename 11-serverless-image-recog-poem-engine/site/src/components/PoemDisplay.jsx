import { motion } from 'framer-motion'
import { Download, Share2, RefreshCw, Sparkles, Tag } from 'lucide-react'

const PoemDisplay = ({ poem, labels, image, onReset }) => {
  const handleDownload = () => {
    const element = document.createElement('a')
    const file = new Blob([poem], { type: 'text/plain' })
    element.href = URL.createObjectURL(file)
    element.download = 'ai-generated-poem.txt'
    document.body.appendChild(element)
    element.click()
    document.body.removeChild(element)
  }

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'AI Generated Poem',
          text: poem,
        })
      } catch (err) {
        console.log('Error sharing:', err)
      }
    } else {
      // Fallback: copy to clipboard
      navigator.clipboard.writeText(poem)
      alert('Poem copied to clipboard!')
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      className="space-y-6"
    >
      {/* Success Header */}
      <motion.div
        initial={{ scale: 0.9 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.2 }}
        className="text-center"
      >
        <div className="inline-flex items-center gap-2 px-4 py-2 bg-green-100 text-green-800 rounded-full mb-4">
          <Sparkles className="w-4 h-4" />
          <span className="font-medium">Poetry Generated Successfully!</span>
        </div>
      </motion.div>

      <div className="grid md:grid-cols-2 gap-6">
        {/* Image Display */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.3 }}
          className="glass-effect rounded-2xl p-6"
        >
          <h3 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
            <Tag className="w-5 h-5" />
            Your Image
          </h3>
          
          <img 
            src={image} 
            alt="Uploaded" 
            className="w-full h-64 object-cover rounded-xl shadow-lg mb-4"
          />
          
          {/* Detected Labels */}
          <div>
            <p className="text-sm font-medium text-gray-600 mb-2">AI Detected:</p>
            <div className="flex flex-wrap gap-2">
              {labels.map((label, index) => (
                <motion.span
                  key={label}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.4 + index * 0.1 }}
                  className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-medium"
                >
                  {label}
                </motion.span>
              ))}
            </div>
          </div>
        </motion.div>

        {/* Poem Display */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.4 }}
          className="glass-effect rounded-2xl p-6"
        >
          <h3 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
            <Sparkles className="w-5 h-5" />
            Generated Poetry
          </h3>
          
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.6 }}
            className="bg-gradient-to-br from-purple-50 to-blue-50 rounded-xl p-6 mb-6"
          >
            <blockquote className="poem-text text-lg leading-relaxed">
              {poem.split('\n').map((line, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.7 + index * 0.2 }}
                  className="mb-2"
                >
                  {line}
                </motion.div>
              ))}
            </blockquote>
          </motion.div>

          {/* Action Buttons */}
          <div className="flex gap-3">
            <button
              onClick={handleDownload}
              className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
            >
              <Download className="w-4 h-4" />
              Download
            </button>
            
            <button
              onClick={handleShare}
              className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium"
            >
              <Share2 className="w-4 h-4" />
              Share
            </button>
          </div>
        </motion.div>
      </div>

      {/* Reset Button */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8 }}
        className="text-center"
      >
        <button
          onClick={onReset}
          className="inline-flex items-center gap-2 px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
        >
          <RefreshCw className="w-4 h-4" />
          Create Another Poem
        </button>
      </motion.div>
    </motion.div>
  )
}

export default PoemDisplay