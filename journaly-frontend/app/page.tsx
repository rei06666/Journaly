"use client"

import Link from "next/link"

export default function Home() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-amber-50 to-orange-100">
      <div className="w-full max-w-2xl px-8 py-12 text-center">
        {/* Logo */}
        <div className="inline-flex items-center justify-center w-20 h-20 bg-amber-100 rounded-2xl mb-6">
          <svg
            className="w-12 h-12 text-amber-600"
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

        <h1 className="text-5xl font-bold text-gray-900 mb-4">Journaly</h1>
        <p className="text-xl text-gray-600 mb-12">
          あなたの毎日を記録しよう
        </p>

        {/* CTA Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link
            href="/signin"
            className="px-8 py-4 bg-amber-500 text-white font-medium rounded-xl hover:bg-amber-600 transition-all duration-200 shadow-lg hover:shadow-xl"
          >
            サインイン
          </Link>
          <Link
            href="/signup"
            className="px-8 py-4 bg-white text-amber-600 font-medium rounded-xl hover:bg-gray-50 transition-all duration-200 shadow-lg hover:shadow-xl border-2 border-amber-500"
          >
            アカウント作成
          </Link>
        </div>

        {/* Features */}
        <div className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8 text-left">
          <div className="bg-white p-6 rounded-xl shadow-md">
            <div className="text-amber-600 mb-3">
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              シンプルな記録
            </h3>
            <p className="text-gray-600 text-sm">
              思いついたことを素早く記録。シンプルで使いやすいインターフェース。
            </p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-md">
            <div className="text-amber-600 mb-3">
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              安全な保存
            </h3>
            <p className="text-gray-600 text-sm">
              あなたのジャーナルは安全に保存され、いつでもアクセス可能。
            </p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-md">
            <div className="text-amber-600 mb-3">
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              振り返りやすい
            </h3>
            <p className="text-gray-600 text-sm">
              過去の記録を簡単に振り返り、自分の成長を実感できる。
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
