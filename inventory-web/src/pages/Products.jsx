import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { getProducts, createProduct, updateProduct, deleteProduct, uploadProductImage, getProductImageUrl, deleteProductImage } from '../api/products'
import { getCategories } from '../api/categories'
import Modal from '../components/Modal'
import Toast from '../components/Toast'

const defaultForm = {
  name: '',
  sku: '',
  description: '',
  category_id: '',
  price: 0,
  cost: 0,
  stock: 0,
  min_stock: 5,
  unit: 'unidad',
  supplier: ''
}

export default function Products() {
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [search, setSearch] = useState('')
  const [categoryFilter, setCategoryFilter] = useState('')
  const [lowStockOnly, setLowStockOnly] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editingProduct, setEditingProduct] = useState(null)
  const [form, setForm] = useState(defaultForm)
  const [pendingImage, setPendingImage] = useState(null)
  const [toast, setToast] = useState(null)
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()

  useEffect(() => {
    loadProducts()
    loadCategories()
  }, [])

 useEffect(() => {
  const category = searchParams.get('category')
  const lowstock = searchParams.get('lowstock')
  if (category) setCategoryFilter(category)
  if (lowstock === 'true') setLowStockOnly(true)
}, [searchParams])

  const loadProducts = async () => {
    try {
      const res = await getProducts()
      setProducts(res.data)
    } catch (error) {
      setToast({ type: 'error', message: 'Error cargando productos.' })
    }
  }

  const loadCategories = async () => {
    try {
      const res = await getCategories()
      setCategories(res.data)
    } catch (error) {
      setToast({ type: 'error', message: 'Error cargando categorías.' })
    }
  }

  const resetModal = () => {
    setForm(defaultForm)
    setEditingProduct(null)
    setPendingImage(null)
    setModalOpen(false)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    try {
      const payload = {
        name: form.name,
        sku: form.sku,
        description: form.description,
        category_id: form.category_id,
        price: Number(form.price) || 0,
        cost: Number(form.cost) || 0,
        stock: Number(form.stock) || 0,
        min_stock: Number(form.min_stock) || 0,
        unit: form.unit,
        supplier: form.supplier
      }

      if (editingProduct) {
        await updateProduct(editingProduct.id, payload)
        setToast({ type: 'success', message: 'Producto actualizado correctamente.' })
      } else {
        const res = await createProduct(payload)
        // Upload pending image if exists
        if (pendingImage && res.data?.id) {
          try {
            await uploadProductImage(res.data.id, pendingImage)
          } catch (error) {
            console.error('Error uploading image:', error)
          }
        }
        setToast({ type: 'success', message: 'Producto creado correctamente.' })
      }

      resetModal()
      setPendingImage(null)
      loadProducts()
    } catch (error) {
      setToast({ type: 'error', message: 'Error guardando el producto.' })
    }
  }

  const handleDelete = async (id) => {
    if (!confirm('¿Eliminar producto?')) return
    try {
      await deleteProduct(id)
      setToast({ type: 'success', message: 'Producto eliminado.' })
      loadProducts()
    } catch (error) {
      setToast({ type: 'error', message: 'No se pudo eliminar el producto.' })
    }
  }

  const handleFileChange = async (e) => {
    const file = e.target.files[0]
    if (file) {
      if (editingProduct) {
        // For existing products, upload immediately
        try {
          await uploadProductImage(editingProduct.id, file)
          setToast({ type: 'success', message: 'Imagen subida correctamente.' })
          loadProducts()
        } catch (error) {
          setToast({ type: 'error', message: 'Error subiendo la imagen.' })
        }
      } else {
        // For new products, store in pending
        setPendingImage(file)
      }
    }
  }

  const handleDeleteImage = async () => {
    if (!editingProduct) return
    try {
      await deleteProductImage(editingProduct.id)
      setToast({ type: 'success', message: 'Imagen eliminada.' })
      loadProducts()
    } catch (error) {
      setToast({ type: 'error', message: 'Error eliminando la imagen.' })
    }
  }

  const getImagePlaceholder = () => (
    <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: '#cbd5e1', display: 'grid', placeItems: 'center', color: '#64748b', fontSize: '1.2rem' }}>
      📦
    </div>
  )

  const renderProductImage = (product) => {
    return (
      <div style={{ width: '40px', height: '40px', borderRadius: '12px', overflow: 'hidden', background: '#f8fafc', display: 'grid', placeItems: 'center' }}>
        <img
          src={getProductImageUrl(product.id)}
          alt={product.name}
          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
          onError={(e) => {
            e.target.style.display = 'none'
            e.target.parentElement.innerHTML = '<div style="width: 40px; height: 40px; border-radius: 12px; background: #cbd5e1; display: grid; place-items: center; color: #64748b; font-size: 1.2rem;">📦</div>'
          }}
        />
      </div>
    )
  }

  const handleEdit = (product) => {
    setEditingProduct(product)
    setForm({
      name: product.name || '',
      sku: product.sku || '',
      description: product.description || '',
      category_id: product.category_id || product.category?.id || '',
      price: product.price || 0,
      cost: product.cost || 0,
      stock: product.stock || 0,
      min_stock: product.min_stock || 0,
      unit: product.unit || 'unidad',
      supplier: product.supplier || '',
      image_url: product.image_url || product.image || ''
    })
    setModalOpen(true)
  }

  const filteredProducts = useMemo(() => {
    return products.filter((product) => {
      const matchesSearch = [product.name, product.sku].some((value) => value?.toString().toLowerCase().includes(search.toLowerCase()))
      const matchesCategory = categoryFilter ? String(product.category_id || product.category?.id) === categoryFilter : true
      const matchesLowStock = lowStockOnly ? Number(product.stock) <= Number(product.min_stock) : true
      return matchesSearch && matchesCategory && matchesLowStock
    })
  }, [products, search, categoryFilter, lowStockOnly])

  const getCategoryName = (product) => {
    return product.category?.name || categories.find((category) => String(category.id) === String(product.category_id))?.name || 'Sin categoría'
  }

  return (
    <div style={{ padding: '1.5rem 0' }}>
      <Toast {...toast} onClose={() => setToast(null)} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginBottom: '1.5rem' }}>
        <p style={{ color: '#64748b', margin: 0 }}>Catálogo</p>
        <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', gap: '1rem', alignItems: 'center' }}>
          <div>
            <h1 style={{ margin: 0, fontSize: '2rem', fontWeight: 700, color: '#0f172a' }}>Productos</h1>
            <p style={{ margin: '0.35rem 0 0', color: '#64748b' }}>Administra inventario y edita productos al instante.</p>
          </div>
          <button
            type="button"
            onClick={() => { resetModal(); setModalOpen(true) }}
            style={{ background: '#2563eb', color: 'white', border: 'none', borderRadius: '999px', padding: '0.85rem 1.3rem', cursor: 'pointer', fontWeight: 600 }}
          >
            + Nuevo producto
          </button>
        </div>
      </div>

      <section style={{ display: 'grid', gap: '1rem', marginBottom: '1.5rem', gridTemplateColumns: '1.2fr 0.8fr' }}>
        <div style={{ display: 'grid', gap: '1rem' }}>
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Buscar por nombre o SKU"
            style={{ width: '100%', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '0.85rem 1rem', background: '#ffffff', color: '#0f172a' }}
          />
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              style={{ width: '100%', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '0.85rem 1rem', background: '#ffffff' }}
            >
              <option value="">Todas las categorías</option>
              {categories.map((category) => (
                <option key={category.id} value={category.id}>{category.name}</option>
              ))}
            </select>
            <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.75rem', color: '#475569' }}>
              <input type="checkbox" checked={lowStockOnly} onChange={(e) => setLowStockOnly(e.target.checked)} />
              Mostrar sólo stock bajo
            </label>
          </div>
        </div>
        <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '22px', boxShadow: '0 18px 45px rgba(15, 23, 42, 0.06)', padding: '1.25rem' }}>
          <p style={{ margin: 0, color: '#64748b', fontSize: '0.95rem' }}>Visión rápida</p>
          <div style={{ display: 'grid', gap: '0.75rem', marginTop: '1rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: '#0f172a', fontWeight: 600 }}>Total de productos</span>
              <span style={{ color: '#1d4ed8', fontWeight: 700 }}>{products.length}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: '#0f172a', fontWeight: 600 }}>Categorías disponibles</span>
              <span style={{ color: '#7c3aed', fontWeight: 700 }}>{categories.length}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: '#0f172a', fontWeight: 600 }}>Productos con stock bajo</span>
              <span style={{ color: '#dc2626', fontWeight: 700 }}>{products.filter((product) => Number(product.stock) <= Number(product.min_stock)).length}</span>
            </div>
          </div>
        </div>
      </section>

      <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '22px', boxShadow: '0 18px 45px rgba(15, 23, 42, 0.06)', overflow: 'hidden' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem 1.5rem', borderBottom: '1px solid #e2e8f0' }}>
          <div>
            <h2 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 700, color: '#0f172a' }}>Productos</h2>
            <p style={{ margin: '0.35rem 0 0', color: '#64748b' }}>Haz clic en cualquier fila para editar el producto.</p>
          </div>
          <span style={{ color: '#475569', fontSize: '0.95rem' }}>{filteredProducts.length} resultados</span>
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', minWidth: '960px', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.02em', fontSize: '0.8rem' }}>
                {['Imagen', 'Nombre', 'SKU', 'Categoría', 'Stock', 'Precio', 'Coste', 'Proveedor', 'Acciones'].map((column) => (
                  <th key={column} style={{ padding: '1rem 1.25rem', borderBottom: '1px solid #e2e8f0', textAlign: 'left' }}>{column}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filteredProducts.map((product) => {
                const lowStock = Number(product.stock) <= Number(product.min_stock)
                return (
                  <tr key={product.id} style={{ cursor: 'pointer', borderBottom: '1px solid #f1f5f9' }} onClick={() => handleEdit(product)}>
                    <td style={{ padding: '1rem 1.25rem' }}>
                      {renderProductImage(product)}
                    </td>
                    <td style={{ padding: '1rem 1.25rem', color: '#0f172a', fontWeight: 600 }}>{product.name}</td>
                    <td style={{ padding: '1rem 1.25rem', color: '#475569' }}>{product.sku || '—'}</td>
                    <td style={{ padding: '1rem 1.25rem', color: '#475569' }}>{getCategoryName(product)}</td>
                    <td style={{ padding: '1rem 1.25rem' }}>
                      <span style={{ padding: '0.45rem 0.75rem', borderRadius: '999px', background: lowStock ? '#fee2e2' : '#dcfce7', color: lowStock ? '#b91c1c' : '#166534', fontWeight: 600, fontSize: '0.85rem' }}>
                        {product.stock} {product.unit || 'u'}
                      </span>
                    </td>
                    <td style={{ padding: '1rem 1.25rem', color: '#0f172a' }}>{Number(product.price).toLocaleString('es-ES', { style: 'currency', currency: 'EUR' })}</td>
                    <td style={{ padding: '1rem 1.25rem', color: '#475569' }}>{Number(product.cost).toLocaleString('es-ES', { style: 'currency', currency: 'EUR' })}</td>
                    <td style={{ padding: '1rem 1.25rem', color: '#475569' }}>{product.supplier || '—'}</td>
                    <td style={{ padding: '1rem 1.25rem' }}>
                      <button
                        type="button"
                        onClick={(event) => {
                          event.stopPropagation()
                          handleDelete(product.id)
                        }}
                        style={{ background: '#ef4444', color: 'white', border: 'none', borderRadius: '999px', padding: '0.65rem 0.95rem', cursor: 'pointer', fontWeight: 600 }}
                      >
                        Eliminar
                      </button>
                    </td>
                  </tr>
                )
              })}
              {filteredProducts.length === 0 && (
                <tr>
                  <td colSpan="9" style={{ padding: '2rem', textAlign: 'center', color: '#94a3b8' }}>No hay productos que coincidan con los filtros.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal open={modalOpen} title={editingProduct ? 'Editar producto' : 'Nuevo producto'} onClose={resetModal}>
        <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '1rem' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Nombre
              <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }} />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              SKU
              <input value={form.sku} onChange={(e) => setForm({ ...form, sku: e.target.value })} style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }} />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Descripción
              <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} rows="3" style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }} />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569', gridColumn: '1 / -1' }}>
              Imagen
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{ width: '80px', height: '80px', borderRadius: '16px', overflow: 'hidden', background: '#f8fafc', display: 'grid', placeItems: 'center', border: '2px dashed #e2e8f0' }}>
                  {editingProduct ? (
                    <img src={getProductImageUrl(editingProduct.id)} alt="preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={(e) => {
                      e.target.style.display = 'none'
                      e.target.parentElement.innerHTML = '<div style="text-align: center; color: #cbd5e1;"><div style="font-size: 1.5rem;">📦</div><div style="font-size: 0.75rem;">Sin imagen</div></div>'
                    }} />
                  ) : pendingImage ? (
                    <img src={URL.createObjectURL(pendingImage)} alt="preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  ) : (
                    <div style={{ textAlign: 'center', color: '#cbd5e1' }}>
                      <div style={{ fontSize: '1.5rem' }}>📦</div>
                      <div style={{ fontSize: '0.75rem' }}>Sin imagen</div>
                    </div>
                  )}
                </div>
                <div style={{ flex: 1 }}>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleFileChange}
                    style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}
                  />
                  <p style={{ fontSize: '0.85rem', color: '#64748b', margin: '0.5rem 0 0' }}>Soporta: JPG, PNG, GIF, WebP</p>
                  {editingProduct && (
                    <button
                      type="button"
                      onClick={handleDeleteImage}
                      style={{ marginTop: '0.5rem', background: '#ef4444', color: 'white', border: 'none', borderRadius: '999px', padding: '0.65rem 0.95rem', cursor: 'pointer', fontWeight: 600, fontSize: '0.9rem' }}
                    >
                      Eliminar imagen
                    </button>
                  )}
                </div>
              </div>
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Categoría
              <select value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })} style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }}>
                <option value="">Selecciona una categoría</option>
                {categories.map((category) => (
                  <option key={category.id} value={category.id}>{category.name}</option>
                ))}
              </select>
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Proveedor
              <input value={form.supplier} onChange={(e) => setForm({ ...form, supplier: e.target.value })} style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }} />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Precio
              <input type="number" step="0.01" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }} />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Coste
              <input type="number" step="0.01" value={form.cost} onChange={(e) => setForm({ ...form, cost: e.target.value })} style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }} />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Stock
              <input type="number" value={form.stock} onChange={(e) => setForm({ ...form, stock: e.target.value })} style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }} />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Stock mínimo
              <input type="number" value={form.min_stock} onChange={(e) => setForm({ ...form, min_stock: e.target.value })} style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }} />
            </label>
            <label style={{ display: 'grid', gap: '0.45rem', color: '#475569' }}>
              Unidad
              <input value={form.unit} onChange={(e) => setForm({ ...form, unit: e.target.value })} style={{ width: '100%', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '0.95rem 1rem' }} />
            </label>
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
            <button type="button" onClick={resetModal} style={{ background: '#f1f5f9', color: '#475569', border: 'none', borderRadius: '999px', padding: '0.85rem 1.25rem', cursor: 'pointer' }}>Cancelar</button>
            <button type="submit" style={{ background: '#2563eb', color: 'white', border: 'none', borderRadius: '999px', padding: '0.85rem 1.25rem', cursor: 'pointer', fontWeight: 700 }}>{editingProduct ? 'Actualizar producto' : 'Crear producto'}</button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
