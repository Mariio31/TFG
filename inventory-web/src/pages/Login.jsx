import { useState } from 'react'
import { login, register } from '../api/auth'

export default function Login({ onLogin }) {
  const [isRegistering, setIsRegistering] = useState(false)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    try {
      if (isRegistering) {
        await register({ name, email, password })
        setSuccess('Cuenta creada correctamente. Inicia sesión.')
        setIsRegistering(false)
        setName('')
        setEmail('')
        setPassword('')
      } else {
        const res = await login(email, password)
        localStorage.setItem('token', res.data.access_token)
        onLogin()
      }
    } catch (err) {
      setError(isRegistering ? 'Error al registrarse. El email puede estar en uso.' : 'Email o contraseña incorrectos')
    }
  }

  const inputStyle = { width: '100%', padding: '0.5rem', marginTop: '0.25rem', borderRadius: '4px', border: '1px solid #ddd', boxSizing: 'border-box' }

  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', background: '#f3f4f6' }}>
      <div style={{ background: 'white', padding: '2rem', borderRadius: '8px', width: '350px', boxShadow: '0 2px 10px rgba(0,0,0,0.1)' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '0.25rem', color: '#111827' }}>Inventory App</h2>
        <p style={{ textAlign: 'center', color: '#6b7280', fontSize: '0.9rem', marginBottom: '1.5rem' }}>
          {isRegistering ? 'Crea tu cuenta' : 'Accede a tu cuenta'}
        </p>

        {error && <p style={{ color: '#ef4444', textAlign: 'center', marginBottom: '1rem', fontSize: '0.9rem' }}>{error}</p>}
        {success && <p style={{ color: '#10b981', textAlign: 'center', marginBottom: '1rem', fontSize: '0.9rem' }}>{success}</p>}

        <form onSubmit={handleSubmit}>
          {isRegistering && (
            <div style={{ marginBottom: '1rem' }}>
              <label>Nombre</label>
              <input type="text" value={name} onChange={(e) => setName(e.target.value)} style={inputStyle} required />
            </div>
          )}
          <div style={{ marginBottom: '1rem' }}>
            <label>Email</label>
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} style={inputStyle} required />
          </div>
          <div style={{ marginBottom: '1.5rem' }}>
            <label>Contraseña</label>
            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} style={inputStyle} required />
          </div>
          <button
            type="submit"
            style={{ width: '100%', padding: '0.75rem', background: '#3b82f6', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontSize: '1rem' }}
          >
            {isRegistering ? 'Crear cuenta' : 'Iniciar sesión'}
          </button>
        </form>

        <p style={{ textAlign: 'center', marginTop: '1rem', fontSize: '0.9rem', color: '#6b7280' }}>
          {isRegistering ? '¿Ya tienes cuenta?' : '¿No tienes cuenta?'}{' '}
          <span
            onClick={() => { setIsRegistering(!isRegistering); setError(''); setSuccess('') }}
            style={{ color: '#3b82f6', cursor: 'pointer' }}
          >
            {isRegistering ? 'Inicia sesión' : 'Regístrate'}
          </span>
        </p>

        <div style={{ marginTop: '1.5rem', borderTop: '1px solid #e5e7eb', paddingTop: '1.5rem', textAlign: 'center' }}>
          <p style={{ fontSize: '0.85rem', color: '#6b7280', marginBottom: '0.75rem' }}>¿Prefieres usar la app móvil?</p>
          <a
            href="https://inventory-web-tfg.s3.amazonaws.com/app-release.apk"
            download
            style={{ display: 'inline-block', padding: '0.6rem 1.2rem', background: '#10b981', color: 'white', borderRadius: '4px', textDecoration: 'none', fontSize: '0.9rem' }}
          >
            Descargar app Android
          </a>
        </div>
      </div>
    </div>
  )
}