"use client";

import { useQuery } from "@tanstack/react-query";

export function Header() {
  const { isError } = useQuery({
    queryKey: ["health"],
    queryFn: async () => {
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"}/api/health`
      );
      if (!res.ok) throw new Error("API down");
      return res.json();
    },
    refetchInterval: 15_000,
  });

  return (
    <header className="border-b border-border-primary bg-bg-card px-6 py-4">
      <div className="max-w-[1400px] mx-auto flex items-center justify-between">
        <h1 className="text-xl font-semibold text-text-primary">
          Acquisition System
        </h1>
        <div className="flex items-center gap-2 text-sm text-text-secondary">
          <span
            className={`inline-block w-2 h-2 rounded-full ${
              isError ? "bg-accent-hot" : "bg-accent-green"
            }`}
          />
          {isError ? "Disconnected" : "Connected"}
        </div>
      </div>
    </header>
  );
}
