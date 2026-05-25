import { useEffect, useState } from 'react'
import { getUsers, createUser, deleteUser } from '../api/auth'
import Modal from '../components/Modal'
import Toast from '../components/Toast'

const defaultForm = {
  name: '',
  email: '',
  password: '',
  role: 'employee'
}

const roleStyles = {
  admin: { background: '#ede9fe', color: '#6b21a8' },
  manager: { background: '#fed7aa', color: '#92400e' },
  employee: { background: '#e5e7eb', color: '#374151' }
}

export default function Users() {
  const [users, setUsers] = useState([])
  const [currentUserId, setCurrentUserId] = useState(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [form, setForm] = useState(defaultForm)
  const [toast, setToast] = useState(null)
  const [passwordErrors, setPasswordErrors] = useState({})

  useEffect(() => {
    loadUsers()
    const token = localStorage.getItem('token')
    if (token) {
      try {
        const payload = JSON.parse(atob(token.split('.')[1]))
        setCurrentUserId(payload.sub || payload.user_id)
      } catch (e) {
        console.error('Error parsing token:', e)
      }
    }
  }, [])

  const loadUsers = async () => {
    try {
      const res = await getUsers()
      setUsers(res.data)
    } catch (error) {
      setToast({ type: 'error', message: 'Error cargando usuarios.' })
    }
  }

  const validatePassword = (password) => {
    const errors = {}
    if (password.length < 8) {
      errors.minLength = 'Mínimo 8 caracteres'
    }
    if (!/[A-Z]/.test(password)) {
      errors.uppercase = 'Debe contener al menos una mayúscula'
    }
    return errors
  }

  const handlePasswordChange = (value) => {
    setForm({ ...form, password: value })
    setPasswordErrors(validatePassword(value))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const errors = validatePassword(form.password)
    if (Object.keys(errors).length > 0) {
      setToast({ type: 'error', message: 'La contraseña no cumple los requisitos.' })
      return
    }

    try {
      await createUser({
        name: form.name,
        email: form.email,
        password: form.password,
        role: form.role
      })
      setToast({ type: 'success', message: 'Usuario creado correctamente.' })
      setForm(defaultForm)
      setPasswordErrors({})
      setModalOpen(false)
      loadUsers()
    } catch (error) {
      setToast({ type: 'error', message: 'Error creando el usuario.' })
    }
  }

  const handleDelete = async (userId) => {
    if (userId === currentUserId) {
      setToast({ type: 'error', message: 'No puedes eliminarte a ti mismo.' })
      return
    }
    if (!confirm('¿Eliminar usuario?')) return
    try {
      await deleteUser(userId)
      setToast({ type: 'success', message: 'Usuario eliminado.' })
      loadUsers()
    } catch (error) {
      setToast({ type: 'error', message: 'No se pudo eliminar el usuario.' })
    }
  }

  return (
    <div style={{ padding: '1.5rem 0' }}>
      <Toast {...toast} onClose={() => setToast(null)} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginBottom: '1.5rem' }}>
        <p style={{ color: '#64748b', margin: 0 }}>Administración</p>
        <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', gap: '1rem', alignItems: 'center' }}>
          <div>
            <h1 style={{ margin: 0, fontSize: '2rem', fontWeight: 700, color: '#0f172a' }}>Usuarios</h1>
            <p style={{ margin: '0.35rem 0 0', color: '#64748b' }}>Gestiona usuarios y roles de la aplicación.</p>
          </div>
          <button
            type="button"
            onClick={() => { setForm(defaultForm); setPasswordErrors({}); setModalOpen(true) }}
            style={{ background: '#2563eb', color: 'white', border: 'none', borderRadius: '999px', padding: '0.85rem 1.3rem', cursor: 'pointer', fontWeight: 600 }}
          >
            + Nuevo usuario
          </button>
        </div>
      </div>

      <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '22px', boxShadow: '0 18px 45px rgba(15, 23, 42, 0.06)', overflow: 'hidden' }}>
        <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid #e2e8f0' }}>
          <h2 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 700, color: '#0f172a' }}>Listado de usuarios</h2>
          <p style={{ margin: '0.35rem 0 0', color: '#64748b' }}>Visualiza y administra todos los usuarios del sistema.</p>
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', minWidth: '720px', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.02em', fontSize: '0.8rem' }}>
                {['Nombre', 'Email', 'Rol', 'Acciones'].map((column) => (
                  <th key={column} style={{ padding: '1rem 1.25rem', borderBottom: '1px solid #e2e8f0', textAlign: 'left' }}>{column}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {users.map((user) => {
                const isCurrent = user.id === currentUserId
                return (
                  <tr key={user.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <td style={{ padding: '1rem 1.25rem', color: '#0f172a', fontWeight: 600 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        {isCurrent && <span style={{ fontSize: '1.1rem' }}>🔒</span>}
                        {user.name}
                      </div>
                    </td>
                    <td style={{ padding: '1rem 1.25rem', color: '#475569' }}>{user.email}</td>
                    <td style={{ padding: '1rem 1.25rem' }}>
                      <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', padding: '0.4rem 0.85rem', borderRadius: '999px', fontSize: '0.85rem', fontWeight: 600, textTransform: 'capitalize', ...roleStyles[user.role] }}>
                        {user.role}
                      </span>
                    </td>
                    <td style={{ padding: '1rem 1.25rem' }}>
                      {isCurrent ? (
                        <span style={{ color: '#94a3b8', fontSize: '0.95rem' }}>Usuario actual</span>
                      ) : (
                        <button
                          type="button"
                          onClick={() => handleDelete(user.id)}
                          style={{ background: '#ef4444', color: 'white', border: 'none', borderRadius: '999px', padding: '0.65rem 0.95rem', cursor: 'pointer', fontWeight: 600 }}
                        >
                          Eliminar
                        </button>
                      )}
                    </td>
                  </tr>
                )
              })}
              {users.length === 0 && (
                <tr>
                  <td colSpan="4" style={{ padding: '2rem', textAlign: 'center', color: '#94a3b8' }}>No hay usuarios registrados.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal open={modalOpen} title="Crear nuevo usuario" onClose={() => setModalOpen(false)}>
        <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '1rem' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Nombre
              <input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                required
                style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
              />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Email
              <input
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                required
                style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
              />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569', gridColumn: '1 / -1' }}>
              Contraseña
              <input
                type="password"
                value={form.password}
                onChange={(e) => handlePasswordChange(e.target.value)}
                required
                style={{
                  width: '100%',
                  borderRadius: '14px',
                  border: Object.keys(passwordErrors).length > 0 ? '2px solid #ef4444' : '1px solid #e2e8f0',
                  padding: '0.95rem 1rem'
                }}
              />
              {Object.keys(passwordErrors).length > 0 && (
                <div style={{ fontSize: '0.85rem', color: '#ef4444', marginTop: '0.25rem' }}>
                  {Object.values(passwordErrors).map((error) => (
                    <div key={error}>✗ {error}</div>
                  ))}
                </div>
              )}
              {Object.keys(passwordErrors).length === 0 && form.password && (
                <div style={{ fontSize: '0.85rem', color: '#22c55e', marginTop: '0.25rem' }}>✓ Contraseña válida</div>
              )}
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Rol
              <select
                value={form.role}
                onChange={(e) => setForm({ ...form, role: e.target.value })}
                style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
              >
                <option value="employee">Empleado</option>
                <option value="manager">Gerente</option>
              </select>
            </label>
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              style={{ background: '#f1f5f9', color: '#475569', border: 'none', borderRadius: '999px', padding: '0.85rem 1.25rem', cursor: 'pointer' }}
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={Object.keys(passwordErrors).length > 0 || !form.password}
              style={{
                background: Object.keys(passwordErrors).length > 0 || !form.password ? '#cbd5e1' : '#2563eb',
                color: 'white',
                border: 'none',
                borderRadius: '999px',
                padding: '0.85rem 1.25rem',
                cursor: Object.keys(passwordErrors).length > 0 ? 'not-allowed' : 'pointer',
                fontWeight: 700
              }}
            >
              Crear usuario
            </button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
