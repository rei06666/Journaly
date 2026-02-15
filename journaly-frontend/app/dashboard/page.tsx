"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { useRouter, useSearchParams } from "next/navigation"

interface Journal {
  id: string
  title: string
  content: string
  userId: string
  createdAt: string
  updatedAt: string
}

export default function DashboardPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [journals, setJournals] = useState<Journal[]>([])
  const [title, setTitle] = useState("")
  const [content, setContent] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [userId, setUserId] = useState<string>("")

  useEffect(() => {
    // URLパラメータからuserIdを取得
    const userIdFromUrl = searchParams.get('userId')
    
    if (userIdFromUrl) {
      setUserId(userIdFromUrl)
      fetchJournals(userIdFromUrl)
    }
  }, [searchParams])

  const fetchJournals = async (userId: string) => {
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001"
      const res = await fetch(`${apiUrl}/journals?userId=${userId}`)
      
      if (res.ok) {
        const data = await res.json()
        setJournals(data)
      }
    } catch (error) {
      console.error('Failed to fetch journals:', error)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!title.trim() || !content.trim()) return

    setIsSubmitting(true)

    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001"
      const res = await fetch(`${apiUrl}/journals`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: title.trim(),
          content: content.trim(),
          userId,
        }),
      })

      if (res.ok) {
        setTitle("")
        setContent("")
        fetchJournals(userId)
      }
    } catch (error) {
      console.error('Failed to create journal:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm("このジャーナルを削除しますか？")) return

    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001"
      const res = await fetch(`${apiUrl}/journals/${id}?userId=${userId}`, {
        method: "DELETE",
      })

      if (res.ok) {
        fetchJournals(userId)
      }
    } catch (error) {
      console.error('Failed to delete journal:', error)
    }
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString("ja-JP", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-amber-50 to-orange-100">
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
          <Link href="/dashboard" className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-amber-500 rounded-lg flex items-center justify-center">
              <svg
                className="w-5 h-5 text-white"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                />
              </svg>
            </div>
            <h1 className="text-xl font-bold text-gray-900">Journaly</h1>
          </Link>
          <button
            onClick={() => {
              router.push('/')
            }}
            className="px-4 py-2 text-sm text-white bg-amber-500 hover:bg-amber-600 rounded-lg transition-colors"
          >
            サインアウト
          </button>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-8 space-y-8">
        {/* 追加フォーム */}
        <div className="bg-white rounded-2xl shadow-xl p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">新しいジャーナル</h2>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label
                htmlFor="title"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                タイトル
              </label>
              <input
                id="title"
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none transition-all text-gray-900 placeholder:text-gray-400"
                placeholder="今日のできごと"
              />
            </div>

            <div>
              <label
                htmlFor="content"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                内容
              </label>
              <textarea
                id="content"
                value={content}
                onChange={(e) => setContent(e.target.value)}
                required
                rows={6}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none transition-all resize-none text-gray-900 placeholder:text-gray-400"
                placeholder="今日あったこと、感じたことを書いてみましょう..."
              />
            </div>

            <button
              type="submit"
              disabled={isSubmitting || !title.trim() || !content.trim()}
              className="w-full py-3 bg-amber-500 text-white font-medium rounded-xl hover:bg-amber-600 disabled:bg-amber-300 disabled:cursor-not-allowed transition-all duration-200"
            >
              {isSubmitting ? "保存中..." : "保存する"}
            </button>
          </form>
        </div>

        {/* ジャーナル一覧 */}
        {journals.length > 0 && (
          <div>
            <h2 className="text-2xl font-bold text-gray-900 mb-6">ジャーナル一覧</h2>
            <div className="space-y-4">
              {journals.map((journal) => (
                <div
                  key={journal.id}
                  className="bg-white rounded-2xl shadow-lg p-6 hover:shadow-xl transition-shadow duration-200"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-gray-900 mb-2">
                        {journal.title}
                      </h3>
                      <p className="text-gray-600 line-clamp-3 whitespace-pre-wrap">
                        {journal.content}
                      </p>
                      <p className="text-sm text-gray-400 mt-3">
                        {formatDate(journal.createdAt)}
                      </p>
                    </div>
                    <button
                      onClick={() => handleDelete(journal.id)}
                      className="ml-4 p-2 text-gray-400 hover:text-red-500 transition-colors"
                      aria-label="削除"
                    >
                      <svg
                        className="w-5 h-5"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                        />
                      </svg>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>
    </div>
  )
}
