"use client"

import { useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"

export default function SignInPage() {
  const router = useRouter()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState("")

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError("")

    console.log('=== サインイン開始 ===')
    console.log('Email:', email)
    console.log('Password:', password ? '***' : '(empty)')

    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001"
      console.log('API URL:', apiUrl)
      console.log('リクエスト送信中...')
      
      const res = await fetch(`${apiUrl}/users/signin`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      })

      console.log('レスポンス受信:', res.status, res.statusText)

      if (!res.ok) {
        const data = await res.json()
        console.log('エラーレスポンス:', data)
        throw new Error(data.message || "サインインに失敗しました")
      }

      const user = await res.json()
      console.log("Signed in user:", user)
      
      // ユーザーIDをクエリパラメータで渡す
      if (user.id) {
        router.push(`/dashboard?userId=${user.id}`)
      } else {
        throw new Error("ユーザー情報が取得できませんでした")
      }
    } catch (err) {
      console.error('=== エラー発生 ===', err)
      setError(err instanceof Error ? err.message : "エラーが発生しました")
    } finally {
      setIsLoading(false)
      console.log('=== サインイン処理終了 ===')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-amber-50 to-orange-100">
      <div className="w-full max-w-md px-8 py-12 bg-white rounded-2xl shadow-xl">
        {/* Logo and Title */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-amber-100 rounded-2xl mb-4">
            <svg
              className="w-8 h-8 text-amber-600"
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
          <h1 className="text-3xl font-bold text-gray-900">Journaly</h1>
          <p className="mt-2 text-gray-600">あなたの毎日を記録しよう</p>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
            {error}
          </div>
        )}

        {/* Sign In Form */}
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label
              htmlFor="email"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              メールアドレス
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none transition-all text-gray-900 placeholder:text-gray-400"
              placeholder="mail@example.com"
            />
          </div>

          <div>
            <label
              htmlFor="password"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              パスワード
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none transition-all text-gray-900 placeholder:text-gray-400"
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-3 bg-amber-500 text-white font-medium rounded-xl hover:bg-amber-600 disabled:bg-amber-300 disabled:cursor-not-allowed transition-all duration-200"
          >
            {isLoading ? "サインイン中..." : "サインイン"}
          </button>
        </form>

        {/* Links */}
        <div className="mt-6 text-center space-y-2">
          <Link
            href="/signup"
            className="block text-sm text-amber-600 hover:underline"
          >
            アカウントをお持ちでない方はこちら
          </Link>
          <Link
            href="/forgot-password"
            className="block text-sm text-gray-500 hover:underline"
          >
            パスワードをお忘れの方
          </Link>
        </div>
      </div>
    </div>
  )
}
