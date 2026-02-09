export interface Journal {
  id: string
  title: string
  content: string
  createdAt: string
  updatedAt: string
}

const STORAGE_KEY = "journaly_journals"

export function getJournals(): Journal[] {
  if (typeof window === "undefined") return []
  const data = localStorage.getItem(STORAGE_KEY)
  return data ? JSON.parse(data) : []
}

export function saveJournal(journal: Omit<Journal, "id" | "createdAt" | "updatedAt">): Journal {
  const journals = getJournals()
  const now = new Date().toISOString()
  const newJournal: Journal = {
    ...journal,
    id: crypto.randomUUID(),
    createdAt: now,
    updatedAt: now,
  }
  journals.unshift(newJournal)
  localStorage.setItem(STORAGE_KEY, JSON.stringify(journals))
  return newJournal
}

export function deleteJournal(id: string): void {
  const journals = getJournals().filter((j) => j.id !== id)
  localStorage.setItem(STORAGE_KEY, JSON.stringify(journals))
}
