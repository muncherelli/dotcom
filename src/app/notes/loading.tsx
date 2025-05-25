export default function NotesLoading() {
  return (
    <div className="container mx-auto px-4 py-8 animate-pulse">
      <div className="h-8 w-1/4 bg-gray-200 rounded mb-6"></div>
      
      <div className="space-y-4">
        {[...Array(5)].map((_, index) => (
          <div key={index} className="border rounded-lg p-4">
            <div className="h-5 bg-gray-200 rounded w-3/4 mb-2"></div>
            <div className="h-4 bg-gray-200 rounded w-1/3"></div>
          </div>
        ))}
      </div>
    </div>
  )
}