import type { Metadata } from "next";
import { Providers } from "./providers";
import { Header } from "@/components/header";
import "./globals.css";

export const metadata: Metadata = {
  title: "Acquisition System",
  description: "AI-powered business acquisition pipeline",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen antialiased">
        <Providers>
          <Header />
          <main className="max-w-[1400px] mx-auto px-6 py-6">{children}</main>
        </Providers>
      </body>
    </html>
  );
}
