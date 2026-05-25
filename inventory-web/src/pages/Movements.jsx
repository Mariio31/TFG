import { useEffect, useMemo, useState } from 'react'
import { getMovements, createMovement, updateMovement } from '../api/movements'
import { getProducts } from '../api/products'
import Modal from '../components/Modal'
import Toast from '../components/Toast'

const initialForm = {
  product_id: '',
  product_name: '',
  type: 'entrada',
  quantity: 1,
  reason: '',
  notes: '',
  reference: ''
}

export default function Movements() {
  const [movements, setMovements] = useState([])
  const [products, setProducts] = useState([])
  const [modalOpen, setModalOpen] = useState(false)
  const [editingMovement, setEditingMovement] = useState(null)
  const [form, setForm] = useState(initialForm)
  const [filters, setFilters] = useState({ query: '', type: 'todos', startDate: '', endDate: '' })
  const [toast, setToast] = useState(null)

  useEffect(() => {
    loadMovements()
    loadProducts()
  }, [])

  const loadMovements = async () => {
    try {
      const res = await getMovements()
      setMovements(res.data.sort((a, b) => new Date(b.created_at) - new Date(a.created_at)))
    } catch (error) {
      setToast({ type: 'error', message: 'Error cargando movimientos.' })
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

  const handleProductChange = (value) => {
    const product = products.find((p) => String(p.id) === String(value))
    setForm({ ...form, product_id: value, product_name: product?.name || '' })
  }

  const handleEdit = (movement) => {
    setEditingMovement(movement)
    setForm({
      product_id: movement.product_id || movement.product?.id || '',
      product_name: movement.product_name || movement.product?.name || '',
      type: movement.type || 'entrada',
      quantity: movement.quantity || 1,
      reason: movement.reason || '',
      notes: movement.notes || '',
      reference: movement.reference || ''
    })
    setModalOpen(true)
  }

  const resetModal = () => {
    setForm(initialForm)
    setEditingMovement(null)
    setModalOpen(false)
  }

  const handleSubmit = async (event) => {
    event.preventDefault()

    try {
      const payload = {
        ...form,
        quantity: Number(form.quantity) || 0
      }

      if (editingMovement) {
        await updateMovement(editingMovement.id, payload)
        setToast({ type: 'success', message: 'Movimiento actualizado correctamente.' })
      } else {
        await createMovement(payload)
        setToast({ type: 'success', message: 'Movimiento creado correctamente.' })
      }

      resetModal()
      loadMovements()
    } catch (error) {
      setToast({ type: 'error', message: editingMovement ? 'Error actualizando el movimiento.' : 'Error creando el movimiento.' })
    }
  }

  const filteredMovements = useMemo(() => {
    const query = filters.query.toLowerCase()
    return movements.filter((movement) => {
      const matchesQuery = [movement.product_name, movement.reference].some((value) => value?.toString().toLowerCase().includes(query))
      const matchesType = filters.type === 'todos' || movement.type === filters.type
      const dateValue = new Date(movement.created_at)
      const matchesStart = filters.startDate ? dateValue >= new Date(filters.startDate) : true
      const matchesEnd = filters.endDate ? dateValue <= new Date(filters.endDate) : true
      return matchesQuery && matchesType && matchesStart && matchesEnd
    })
  }, [movements, filters])

  const typeStyle = (type) => {
    if (type === 'entrada') return { background: '#dcfce7', color: '#166534' }
    if (type === 'salida') return { background: '#fee2e2', color: '#b91c1c' }
    return { background: '#fef3c7', color: '#92400e' }
  }

  return (
    <div style={{ padding: '1.5rem 0' }}>
      <Toast {...toast} onClose={() => setToast(null)} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginBottom: '1.5rem' }}>
        <p style={{ color: '#64748b', margin: 0 }}>Movimientos</p>
        <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', gap: '1rem', alignItems: 'center' }}>
          <div>
            <h1 style={{ margin: 0, fontSize: '2rem', fontWeight: 700, color: '#0f172a' }}>Movimientos</h1>
            <p style={{ margin: '0.35rem 0 0', color: '#64748b' }}>Registra entradas, salidas y ajustes de inventario.</p>
          </div>
          <button
            type="button"
            onClick={() => { resetModal(); setModalOpen(true) }}
            style={{ background: '#2563eb', color: 'white', border: 'none', borderRadius: '999px', padding: '0.85rem 1.3rem', cursor: 'pointer', fontWeight: 600 }}
          >
            + Nuevo movimiento
          </button>
        </div>
      </div>

      <section style={{ display: 'grid', gap: '1rem', marginBottom: '1.5rem', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))' }}>
        <input
          value={filters.query}
          onChange={(e) => setFilters({ ...filters, query: e.target.value })}
          placeholder="Buscar por producto o referencia"
          style={{ borderRadius: '16px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem', background: '#ffffff', color: '#0f172a', width: '100%' }}
        />
        <select
          value={filters.type}
          onChange={(e) => setFilters({ ...filters, type: e.target.value })}
          style={{ borderRadius: '16px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem', background: '#ffffff', color: '#0f172a', width: '100%' }}
        >
          <option value="todos">Todos los tipos</option>
          <option value="entrada">Entrada</option>
          <option value="salida">Salida</option>
          <option value="ajuste">Ajuste</option>
        </select>
        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
          <label style={{ display: 'grid', gap: '0.35rem', width: '100%' }}>
            Desde
            <input type="date" value={filters.startDate} onChange={(e) => setFilters({ ...filters, startDate: e.target.value })} style={{ borderRadius: '16px', border: '1px solid #e2e8f0', padding: '0.85rem 1rem' }} />
          </label>
          <label style={{ display: 'grid', gap: '0.35rem', width: '100%' }}>
            Hasta
            <input type="date" value={filters.endDate} onChange={(e) => setFilters({ ...filters, endDate: e.target.value })} style={{ borderRadius: '16px', border: '1px solid #e2e8f0', padding: '0.85rem 1rem' }} />
          </label>
        </div>
      </section>

      <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '22px', boxShadow: '0 18px 45px rgba(15, 23, 42, 0.06)', overflow: 'hidden' }}>
        <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: '0.75rem' }}>
          <div>
            <h2 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 700, color: '#0f172a' }}>Historico de movimientos</h2>
            <p style={{ margin: '0.35rem 0 0', color: '#64748b' }}>Filtra y busca registros por producto, tipo o fecha.</p>
          </div>
          <span style={{ color: '#475569', fontSize: '0.95rem' }}>{filteredMovements.length} resultados</span>
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', minWidth: '820px', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.02em', fontSize: '0.78rem' }}>
                {['Producto', 'Tipo', 'Cantidad', 'Motivo', 'Referencia', 'Fecha', 'Acciones'].map((column) => (
                  <th key={column} style={{ padding: '1rem 1.25rem', borderBottom: '1px solid #e2e8f0', textAlign: 'left' }}>{column}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filteredMovements.map((movement) => (
                <tr key={movement.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                  <td style={{ padding: '1rem 1.25rem', color: '#0f172a', fontWeight: 600 }}>{movement.product_name || 'Producto'}</td>
                  <td style={{ padding: '1rem 1.25rem' }}>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', padding: '0.4rem 0.85rem', borderRadius: '999px', ...typeStyle(movement.type), fontWeight: 700, textTransform: 'capitalize', fontSize: '0.85rem' }}>{movement.type}</span>
                  </td>
                  <td style={{ padding: '1rem 1.25rem', color: '#0f172a' }}>{movement.quantity}</td>
                  <td style={{ padding: '1rem 1.25rem', color: '#475569' }}>{movement.reason || '—'}</td>
                  <td style={{ padding: '1rem 1.25rem', color: '#475569' }}>{movement.reference || '—'}</td>
                  <td style={{ padding: '1rem 1.25rem', color: '#64748b' }}>{new Date(movement.created_at).toLocaleDateString()}</td>
                  <td style={{ padding: '1rem 1.25rem' }}>
                    <button
                      type="button"
                      onClick={() => handleEdit(movement)}
                      style={{ background: '#3b82f6', color: 'white', border: 'none', borderRadius: '999px', padding: '0.65rem 0.95rem', cursor: 'pointer', fontWeight: 600 }}
                    >
                      Editar
                    </button>
                  </td>
                </tr>
              ))}
              {filteredMovements.length === 0 && (
                <tr>
                  <td colSpan="7" style={{ padding: '2rem', textAlign: 'center', color: '#94a3b8' }}>No se encontraron movimientos para esos filtros.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal open={modalOpen} title={editingMovement ? 'Editar movimiento' : 'Registrar movimiento'} onClose={resetModal}>
        <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '1rem' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Producto
              <select
                value={form.product_id}
                onChange={(e) => handleProductChange(e.target.value)}
                required
                style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
              >
                <option value="">Selecciona un producto</option>
                {products.map((product) => (
                  <option key={product.id} value={product.id}>{product.name}</option>
                ))}
              </select>
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Tipo
              <select
                value={form.type}
                onChange={(e) => setForm({ ...form, type: e.target.value })}
                style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
              >
                <option value="entrada">Entrada</option>
                <option value="salida">Salida</option>
                <option value="ajuste">Ajuste</option>
              </select>
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Cantidad
              <input
                type="number"
                min="1"
                value={form.quantity}
                onChange={(e) => setForm({ ...form, quantity: Number(e.target.value) || 1 })}
                required
                style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
              />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Referencia
              <input
                value={form.reference}
                onChange={(e) => setForm({ ...form, reference: e.target.value })}
                style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
              />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Motivo
              <input
                value={form.reason}
                onChange={(e) => setForm({ ...form, reason: e.target.value })}
                style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
              />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569', gridColumn: '1 / -1' }}>
              Notas
              <textarea
                value={form.notes}
                onChange={(e) => setForm({ ...form, notes: e.target.value })}
                rows="3"
                style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
              />
            </label>
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
            <button type="button" onClick={resetModal} style={{ background: '#f1f5f9', color: '#475569', border: 'none', borderRadius: '999px', padding: '0.85rem 1.25rem', cursor: 'pointer' }}>Cancelar</button>
            <button type="submit" style={{ background: '#2563eb', color: 'white', border: 'none', borderRadius: '999px', padding: '0.85rem 1.25rem', cursor: 'pointer', fontWeight: 700 }}>{editingMovement ? 'Actualizar movimiento' : 'Guardar movimiento'}</button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
