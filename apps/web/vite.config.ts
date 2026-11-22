import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react()],
  // 固定 IPv4：部分 Windows 环境下 localhost 解析到 ::1 会被拒绝
  server: { host: '127.0.0.1', port: 5173, strictPort: true },
});
