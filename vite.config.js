import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  // Electron 生产模式用 file:// 加载，资源必须是相对路径，否则白屏
  base: './',
  plugins: [vue()],
  server: {
    host: true,
    proxy: {
      // 前端所有 /api 请求转发给 FastAPI 后端
      '/api': 'http://localhost:3100',
    },
  },
})
