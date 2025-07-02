import ImageResizer from "@/components/image-resizer"

export default function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100 py-12 px-4 dark:bg-gray-900">
      <ImageResizer />
    </div>
  )
}
// This is the main page of the application where the ImageResizer component is rendered.