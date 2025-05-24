import { ReactNode } from "react";

export default function NotesLayout({ children }: { children: ReactNode }) {
  return (
    <main className="min-h-screen bg-white">
      <div className="max-w-4xl mx-auto">{children}</div>
    </main>
  );
}