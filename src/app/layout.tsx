import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import localFont from "next/font/local";
import "./globals.css";

const chomsky = localFont({
  src: [
    {
      path: "../fonts/Chomsky.woff2",
      weight: "400",
      style: "normal",
    },
    {
      path: "../fonts/Chomsky.woff",
      weight: "400",
      style: "normal",
    },
  ],
  variable: "--font-chomsky",
});

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "muncherelli",
  description: "muncherelli",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} ${chomsky.variable} bg-black text-white min-h-screen`}
      >
        {children}
      </body>
    </html>
  );
}
