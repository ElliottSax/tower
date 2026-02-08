import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        bg: {
          primary: "#0f1117",
          card: "#161b22",
          hover: "#1c2129",
        },
        border: {
          primary: "#30363d",
        },
        text: {
          primary: "#e1e4e8",
          secondary: "#8b949e",
        },
        accent: {
          hot: "#f85149",
          warm: "#d29922",
          green: "#3fb950",
          blue: "#388bfd",
        },
      },
    },
  },
  plugins: [],
};

export default config;
