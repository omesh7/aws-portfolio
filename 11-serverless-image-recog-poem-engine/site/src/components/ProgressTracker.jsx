import { motion } from 'framer-motion'
import { CheckCircle } from 'lucide-react'

const ProgressTracker = ({ steps, currentStep }) => {
  return (
    <div className="glass-effect rounded-2xl p-6">
      <div className="flex items-center justify-between">
        {steps.map((step, index) => {
          const Icon = step.icon
          const isActive = index === currentStep
          const isCompleted = index < currentStep
          const isUpcoming = index > currentStep

          return (
            <div key={index} className="flex items-center flex-1">
              {/* Step Circle */}
              <div className="relative">
                <motion.div
                  initial={{ scale: 0.8 }}
                  animate={{ 
                    scale: isActive ? 1.1 : 1,
                    backgroundColor: isCompleted ? '#10b981' : isActive ? '#3b82f6' : '#e5e7eb'
                  }}
                  transition={{ duration: 0.3 }}
                  className={`w-12 h-12 rounded-full flex items-center justify-center ${
                    isCompleted ? 'bg-green-500' : isActive ? 'bg-blue-500' : 'bg-gray-200'
                  }`}
                >
                  {isCompleted ? (
                    <CheckCircle className="w-6 h-6 text-white" />
                  ) : (
                    <Icon className={`w-6 h-6 ${isActive ? 'text-white' : 'text-gray-500'}`} />
                  )}
                </motion.div>

                {/* Pulse animation for active step */}
                {isActive && (
                  <motion.div
                    animate={{ scale: [1, 1.3, 1], opacity: [0.7, 0, 0.7] }}
                    transition={{ duration: 2, repeat: Infinity }}
                    className="absolute inset-0 bg-blue-500 rounded-full"
                  />
                )}
              </div>

              {/* Step Info */}
              <div className="ml-4 flex-1">
                <motion.h4
                  animate={{ 
                    color: isCompleted ? '#10b981' : isActive ? '#3b82f6' : '#6b7280'
                  }}
                  className={`font-semibold ${
                    isCompleted ? 'text-green-600' : isActive ? 'text-blue-600' : 'text-gray-500'
                  }`}
                >
                  {step.label}
                </motion.h4>
                <p className={`text-sm ${
                  isActive ? 'text-gray-700' : 'text-gray-500'
                }`}>
                  {step.description}
                </p>
              </div>

              {/* Connector Line */}
              {index < steps.length - 1 && (
                <div className="flex-1 mx-4">
                  <motion.div
                    initial={{ scaleX: 0 }}
                    animate={{ 
                      scaleX: isCompleted ? 1 : 0,
                      backgroundColor: isCompleted ? '#10b981' : '#e5e7eb'
                    }}
                    transition={{ duration: 0.5, delay: 0.2 }}
                    className="h-0.5 bg-gray-200 origin-left"
                    style={{ transformOrigin: 'left' }}
                  />
                </div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}

export default ProgressTracker