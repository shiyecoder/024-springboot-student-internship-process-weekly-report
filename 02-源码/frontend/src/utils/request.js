import axios from 'axios'
import { ElMessage } from 'element-plus'

/**
 * 统一请求封装：自动带 JWT，统一解包 R<T>，401 时清理登录态。
 * 所有页面只拿 data，不各写一套错误处理。
 */
const request = axios.create({ baseURL: '', timeout: 20000 })

request.interceptors.request.use((cfg) => {
  const token = localStorage.getItem('at_token')
  if (token) cfg.headers.Authorization = 'Bearer ' + token
  return cfg
})

request.interceptors.response.use(
  (res) => {
    const body = res.data
    // 文件流直接返回
    if (body instanceof Blob) return body
    if (body && typeof body === 'object' && 'code' in body) {
      if (body.code === 200) return body.data
      if (body.code === 401) {
        localStorage.removeItem('at_token')
        localStorage.removeItem('at_user')
        if (location.hash.indexOf('/login') < 0) location.hash = '#/login'
      }
      ElMessage.error(body.message || '请求失败')
      return Promise.reject(new Error(body.message || '请求失败'))
    }
    return body
  },
  (err) => {
    ElMessage.error(err.message || '网络异常，请稍后重试')
    return Promise.reject(err)
  }
)

export default request
