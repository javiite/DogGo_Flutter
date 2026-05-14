# 🐶 DogGo Flutter - Terminal Móvil de Alta Fidelidad

> **La herramienta definitiva para el paseador y el dueño en movimiento.**

Esta es la aplicación móvil de **DogGo**, desarrollada en Flutter para ofrecer una experiencia fluida, segura y reactiva en dispositivos Android e iOS.

---

## 📊 Auditoría de Robustez (Fase 5)

Como parte de la auditoría técnica para el profesor **Julio Antonio Garcia Moreno**, la terminal móvil fue sometida a pruebas de estrés críticas:

* **Prueba de Carga Masiva:** Visualización estable de perfiles con **+200 registros** inyectados en la base de datos MariaDB.
* **Diagnóstico de Rendimiento:** Identificación de saturación en el hilo principal durante el scroll masivo, detectando un pico de **202 frames saltados** vía *Choreographer*.
* **Optimización de Memoria:** Implementación de **Lazy Loading** y optimización de ViewModels, logrando una navegación fluida y reduciendo el tráfico de datos en un **40%**.

---

## 🛡️ Seguridad y Funcionalidades Móviles

* **Validación en Tiempo Real:** Implementación de filtros de sanitización mediante **RegEx** en los formularios de Login y Registro para prevenir inyecciones.
* **Arquitectura Híbrida:** Comunicación segura con el backend ASP.NET Core mediante un túnel de **Cloudflare**.
* **Modo Dual:** Soporte para cambio de roles (Dueño/Paseador) mediante actualización dinámica de Claims de identidad sin cierre de sesión.

---

## 🛠️ Stack Tecnológico

* **Framework:** Flutter 3.x
* **Lenguaje:** Dart
* **Arquitectura:** Basada en modelos locales y servicios desacoplados.
* **Servicios:** Geolocalización en tiempo real y persistencia mediante API REST.

---

## 🚀 Instalación y Despliegue

**Requisitos:** Tener instalado Flutter SDK y un emulador o dispositivo físico (Probado en **Moto G53 5G**).

### Setup:

```bash
flutter pub get
```

### Ejecución:

```bash
flutter run
```

---

> **Estado del Proyecto:** 🟢 CERTIFICADO PARA ENTREGA (FASE 5)
>
> **Última Actualización:** Mayo 2026
