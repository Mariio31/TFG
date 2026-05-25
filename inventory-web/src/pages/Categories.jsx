import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getCategories, createCategory, updateCategory, deleteCategory } from '../api/categories'
import { getProducts } from '../api/products'
import Modal from '../components/Modal'
import Toast from '../components/Toast'

const defaultForm = {
  name: '',
  description: '',
  color: '#2563eb'
}

export default function Categories() {
  const [categories, setCategories] = useState([])
  const [products, setProducts] = useState([])
  const [editCategory, setEditCategory] = useState(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [form, setForm] = useState(defaultForm)
  const [toast, setToast] = useState(null)
  const navigate = useNavigate()

  useEffect(() => {
    loadCategories()
    loadProducts()
  }, [])

  const loadCategories = async () => {
    try {
      const res = await getCategories()
      setCategories(res.data)
    } catch (error) {
      setToast({ type: 'error', message: 'Error cargando categorías.' })
    }
  }

  const loadProducts = async () => {
    try {
      const res = await getProducts()
      setProducts(res.data)
    } catch (error) {
      setToast({ type: 'error', message: 'Error cargando productos.' })
    }
  }

  const openModal = (category = null) => {
    if (category) {
      setEditCategory(category)
      setForm({
        name: category.name || '',
        description: category.description || '',
        color: category.color || '#2563eb'
      })
    } else {
      setEditCategory(null)
      setForm(defaultForm)
    }
    setModalOpen(true)
  }

  const closeModal = () => {
    setModalOpen(false)
    setEditCategory(null)
    setForm(defaultForm)
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    try {
      if (editCategory) {
        await updateCategory(editCategory.id, form)
        setToast({ type: 'success', message: 'Categoría actualizada correctamente.' })
      } else {
        await createCategory(form)
        setToast({ type: 'success', message: 'Categoría creada correctamente.' })
      }
      closeModal()
      loadCategories()
    } catch (error) {
      setToast({ type: 'error', message: 'Error guardando la categoría.' })
    }
  }

  const handleDelete = async (id) => {
    if (!confirm('¿Eliminar categoría?')) return
    try {
      await deleteCategory(id)
      setToast({ type: 'success', message: 'Categoría eliminada.' })
      loadCategories()
    } catch (error) {
      setToast({ type: 'error', message: 'No se pudo eliminar la categoría.' })
    }
  }

  const countsByCategory = useMemo(() => {
    return products.reduce((map, product) => {
      const categoryId = product.category_id || product.category?.id
      if (categoryId) {
        map[categoryId] = (map[categoryId] || 0) + 1
      }
      return map
    }, {})
  }, [products])

  return (
    <div style={{ padding: '1.5rem 0' }}>
      <Toast {...toast} onClose={() => setToast(null)} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginBottom: '1.5rem' }}>
        <p style={{ color: '#64748b', margin: 0 }}>Organización</p>
        <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', gap: '1rem', alignItems: 'center' }}>
          <div>
            <h1 style={{ margin: 0, fontSize: '2rem', fontWeight: 700, color: '#0f172a' }}>Categorías</h1>
            <p style={{ margin: '0.35rem 0 0', color: '#64748b' }}>Crea y administra categorías con trazabilidad visual.</p>
          </div>
          <button
            type="button"
            onClick={() => openModal()}
            style={{ background: '#2563eb', color: 'white', border: 'none', borderRadius: '999px', padding: '0.85rem 1.3rem', cursor: 'pointer', fontWeight: 600 }}
          >
            + Nueva categoría
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gap: '1rem', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))' }}>
        {categories.map((category) => (
          <div
            key={category.id}
            onClick={() => navigate(`/products?category=${category.id}`)}
            style={{
              cursor: 'pointer',
              background: '#ffffff',
              border: '1px solid #e2e8f0',
              borderRadius: '22px',
              boxShadow: '0 18px 45px rgba(15, 23, 42, 0.06)',
              padding: '1.5rem',
              display: 'flex',
              flexDirection: 'column',
              gap: '1.2rem',
              borderLeft: `6px solid ${category.color || '#2563eb'}`
            }}
          >
            <div>
              <p style={{ margin: 0, color: '#0f172a', fontWeight: 700, fontSize: '1.05rem' }}>{category.name}</p>
              <p style={{ margin: '0.5rem 0 0', color: '#64748b', fontSize: '0.95rem' }}>{category.description || 'Sin descripción'}</p>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: '#475569', fontSize: '0.95rem' }}>{countsByCategory[category.id] || 0} productos</span>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button
                  type="button"
                  onClick={(event) => {
                    event.stopPropagation()
                    openModal(category)
                  }}
                  style={{ background: '#e2e8f0', border: 'none', borderRadius: '999px', color: '#0f172a', padding: '0.6rem 0.9rem', cursor: 'pointer' }}
                >
                  Editar
                </button>
                <button
                  type="button"
                  onClick={(event) => {
                    event.stopPropagation()
                    handleDelete(category.id)
                  }}
                  style={{ background: '#ef4444', border: 'none', borderRadius: '999px', color: 'white', padding: '0.6rem 0.9rem', cursor: 'pointer' }}
                >
                  Eliminar
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {categories.length === 0 && (
        <div style={{ marginTop: '1.5rem', padding: '1.5rem', background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '22px', color: '#64748b' }}>
          Aún no hay categorías registradas.
        </div>
      )}

      <Modal open={modalOpen} title={editCategory ? 'Editar categoría' : 'Nueva categoría'} onClose={closeModal}>
        <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '1rem' }}>
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
            Descripción
            <textarea
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              rows="3"
              style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
            />
          </label>
          <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
            Color
            <input
              type="color"
              value={form.color}
              onChange={(e) => setForm({ ...form, color: e.target.value })}
              style={{ width: '5rem', height: '3rem', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.35rem' }}
            />
          </label>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
            <button type="button" onClick={closeModal} style={{ background: '#f1f5f9', color: '#475569', border: 'none', borderRadius: '999px', padding: '0.85rem 1.25rem', cursor: 'pointer' }}>Cancelar</button>
            <button type="submit" style={{ background: '#2563eb', color: 'white', border: 'none', borderRadius: '999px', padding: '0.85rem 1.25rem', cursor: 'pointer', fontWeight: 700 }}>{editCategory ? 'Actualizar categoría' : 'Crear categoría'}</button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
