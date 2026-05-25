import { useState } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Products from './pages/Products'
import Categories from './pages/Categories'
import Movements from './pages/Movements'
import Users from './pages/Users'
import Navbar from './components/Navbar'

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(!!localStorage.getItem('token'))

  const handleLogin = () => setIsLoggedIn(true)

  const handleLogout = () => {
    localStorage.removeItem('token')
    setIsLoggedIn(false)
  }

  if (!isLoggedIn) return <Login onLogin={handleLogin} />

  return (
    <BrowserRouter>
      <div style={{ minHeight: '100vh', background: '#f8fafc' }}>
        <Navbar onLogout={handleLogout} />
        <main style={{ width: '100%', maxWidth: '1400px', margin: '0 auto', padding: '1.5rem 1rem 3rem' }}>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/products" element={<Products />} />
            <Route path="/categories" element={<Categories />} />
            <Route path="/movements" element={<Movements />} />
            <Route path="/users" element={<Users />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}

export default App
