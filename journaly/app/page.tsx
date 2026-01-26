import Link from "next/link"

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-amber-50 to-orange-100">
      <header className="bg-white shadow-sm">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <h1 className="text-xl font-bold text-gray-900">Journaly</h1>
          <Link
            href="/signin"
            className="text-sm text-amber-600 hover:underline"
          >
            サインイン
          </Link>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-8">
        <div className="bg-white rounded-2xl shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">
            ようこそ
          </h2>
          <p className="text-gray-600">
            ここにジャーナルの機能が追加されます。
          </p>
        </div>
      </main>
    </div>
  )
}
