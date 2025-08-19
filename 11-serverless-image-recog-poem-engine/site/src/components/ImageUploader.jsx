import { useState, useRef } from 'react'
import { motion } from 'framer-motion'
import { Upload, Image as ImageIcon, X } from 'lucide-react'

const ImageUploader = ({ onUpload }) => {
  const [dragActive, setDragActive] = useState(false)
  const [preview, setPreview] = useState(null)
  const [selectedFile, setSelectedFile] = useState(null)
  const fileInputRef = useRef(null)

  const handleDrag = (e) => {
    e.preventDefault()
    e.stopPropagation()
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true)
    } else if (e.type === "dragleave") {
      setDragActive(false)
    }
  }

  const handleDrop = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setDragActive(false)
    
    const files = e.dataTransfer.files
    if (files && files[0]) {
      handleFile(files[0])
    }
  }

  const handleChange = (e) => {
    e.preventDefault()
    if (e.target.files && e.target.files[0]) {
      handleFile(e.target.files[0])
    }
  }

  const handleFile = (file) => {
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file')
      return
    }

    if (file.size > 5 * 1024 * 1024) {
      alert('File size must be less than 5MB')
      return
    }

    setSelectedFile(file)
    const reader = new FileReader()
    reader.onload = (e) => setPreview(e.target.result)
    reader.readAsDataURL(file)
  }

  const handleUpload = () => {
    if (selectedFile) {
      onUpload(selectedFile)
    }
  }

  const clearPreview = () => {
    setPreview(null)
    setSelectedFile(null)
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="glass-effect rounded-2xl p-8"
    >
      {!preview ? (
        <div
          className={`relative border-2 border-dashed rounded-xl p-12 text-center transition-all duration-300 ${
            dragActive 
              ? 'border-blue-500 bg-blue-50/50' 
              : 'border-gray-300 hover:border-blue-400 hover:bg-blue-50/30'
          }`}
          onDragEnter={handleDrag}
          onDragLeave={handleDrag}
          onDragOver={handleDrag}
          onDrop={handleDrop}
        >
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleChange}
            className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
          />
          
          <div className="flex flex-col items-center gap-4">
            <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center">
              <Upload className="w-8 h-8 text-blue-600" />
            </div>
            
            <div>
              <h3 className="text-xl font-semibold text-gray-800 mb-2">
                Upload Your Image
              </h3>
              <p className="text-gray-600 mb-4">
                Drag and drop an image here, or click to select
              </p>
              <p className="text-sm text-gray-500">
                Supports JPG, PNG • Max 5MB
              </p>
            </div>
            
            <button
              type="button"
              className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
              onClick={() => fileInputRef.current?.click()}
            >
              Choose Image
            </button>
          </div>
        </div>
      ) : (
        <div className="text-center">
          <div className="relative inline-block mb-6">
            <img 
              src={preview} 
              alt="Preview" 
              className="w-64 h-64 object-cover rounded-xl shadow-lg"
            />
            <button
              onClick={clearPreview}
              className="absolute -top-2 -right-2 w-8 h-8 bg-red-500 text-white rounded-full flex items-center justify-center hover:bg-red-600 transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
          
          <div className="flex gap-4 justify-center">
            <button
              onClick={clearPreview}
              className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
            >
              Choose Different Image
            </button>
            <button
              onClick={handleUpload}
              className="px-8 py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all font-medium shadow-lg hover:shadow-xl transform hover:scale-105"
            >
              Generate Poetry ✨
            </button>
          </div>
        </div>
      )}
    </motion.div>
  )
}

export default ImageUploader