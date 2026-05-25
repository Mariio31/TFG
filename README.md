# Sistema de Gestión de Inventario

Aplicación completa de gestión de inventarios desarrollada como Trabajo de Fin de Grado (TFG).

## Descripción

Este proyecto consiste en el desarrollo de una aplicación integral para la gestión de inventarios orientada a pequeños y medianos negocios. El objetivo principal es facilitar el control de productos, stock y movimientos de inventario mediante una interfaz moderna, intuitiva y funcional.

La aplicación está compuesta por tres componentes principales:

- **Aplicación móvil** (Flutter): Interfaz nativa para dispositivos iOS y Android
- **Aplicación web** (React): Panel de control accesible desde navegador
- **Backend** (FastAPI): API RESTful que gestiona la lógica de negocio y la base de datos

## Características principales

### Gestión de productos
- Creación, edición y eliminación de productos
- Gestión de categorías para organizar el inventario
- Asignación de imágenes a productos
- Control de stock actual y stock mínimo
- Indicadores visuales de stock bajo
- Búsqueda por nombre y SKU
- Filtros por categoría y stock bajo

### Gestión de movimientos
- Registro de entradas y salidas de stock
- Asignación de productos y cantidades
- Registro de motivos y notas
- Historial completo de movimientos
- Filtros por tipo de movimiento
- Eliminación de movimientos con confirmación

### Gestión de usuarios
- Sistema de autenticación con roles
- Roles: Administrador, Gestor y Empleado
- Creación y gestión de usuarios (solo administradores)
- Control de permisos por rol

### Panel de control
- Vista general del inventario
- Resumen de productos, categorías y movimientos
- Alertas de stock bajo
- Lista de últimos movimientos
- Navegación rápida entre secciones

## Arquitectura del proyecto

```
TFG/
├── inventory-api/      # Backend en FastAPI
├── inventory-app/      # Aplicación móvil en Flutter
└── inventory-web/      # Aplicación web en React
```

## Tecnologías utilizadas

### Backend
- Python con FastAPI
- SQLAlchemy para ORM
- Base de datos SQLite
- Autenticación JWT

### Aplicación móvil
- Flutter
- Dart
- HTTP para comunicación con la API
- ImagePicker para gestión de imágenes

### Aplicación web
- React
- Vite
- TailwindCSS
- Axios para comunicación con la API

## Estado del proyecto

El proyecto se encuentra **completado** y totalmente funcional. Todas las características planificadas han sido implementadas y probadas.

## Autor

**Mario Borregán Barral**

**Centro:** CDM FP | Centro de Formación Profesional  
**Ciclo:** Grado Superior en Desarrollo de Aplicaciones Multiplataforma (DAM)  
**Curso:** 2025-2026
