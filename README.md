# Sistema de inventario – Distribuidora VitalSano

Proyecto de **Programación II (ISWZ1103)**. Aplicación de consola en Java, con Programación Orientada a Objetos, para gestionar el inventario de una pequeña distribuidora de alimentos saludables y suplementos que abastece a 35 cafeterías y gimnasios. Su problema: pierde dinero por productos perecederos que caducan en bodega y sufre quiebres de stock en los productos más vendidos.

## Alternativa implementada

**Optimización cuantitativa: EOQ ajustado a las restricciones + stock de seguridad**, apoyada en:

- **FEFO** (First Expired, First Out): al despachar se usa primero el lote que caduca antes y nunca uno vencido.
- **Clasificación ABC**: los productos de mayor valor reciben más stock de seguridad (mayor nivel de servicio).
- **Alertas de caducidad** y retiro de lotes vencidos (merma).

## Estructura del proyecto

```
src/
├── modelo/      Producto (abstracta) ← ProductoPerecedero, ProductoNoPerecedero
│                Lote, Proveedor, RecomendacionPedido, AreaAlmacenamiento (enum), ClaseABC (enum)
├── negocio/     GestorInventario, PlanificadorReposicion, ClasificadorABC, Validador,
│                DatosIniciales, ReglaNegocioException, StockInsuficienteException
└── interfaz/    Main, MenuConsola
```

| Paquete | Responsabilidad |
|---|---|
| `modelo` | Las clases del dominio: qué es un producto, un lote, un proveedor. No leen ni imprimen nada. |
| `negocio` | Las reglas del caso (espacio, presupuesto, horario de recepción, FEFO, ABC, EOQ) y las validaciones. |
| `interfaz` | Menú de consola: pide datos, llama a `negocio` y muestra resultados o mensajes de error. |

### Conceptos de POO aplicados

| Concepto | Dónde se ve |
|---|---|
| **Encapsulamiento** | Atributos privados. `Lote` solo se puede crear y descontar desde `Producto` (constructor y `retirar()` con visibilidad de paquete). `getLotes()` devuelve una lista de solo lectura. Los constructores validan sus datos. |
| **Herencia** | `ProductoPerecedero` y `ProductoNoPerecedero` extienden `Producto`. `StockInsuficienteException` extiende `ReglaNegocioException`. |
| **Polimorfismo** | Métodos abstractos de `Producto` que cada subclase implementa distinto: `getTipo()`, `getAreaAlmacenamiento()`, `getVidaUtilDias()`, `calcularFechaCaducidad()` y `getDiasAlertaCaducidad()`. |
| **Abstracción** | `Producto` es abstracta: no existen productos "genéricos", solo perecederos o no perecederos. |
| **Composición** | Un `Producto` es dueño de sus `Lote` y se asocia a un `Proveedor`. |

## Cómo ejecutarlo

Requiere **JDK 11 o superior** (compila con `--release 11`; probado con JDK 21).

**IntelliJ IDEA:** `File > Open` y elegir esta carpeta → clic derecho sobre `src` → `Mark Directory as > Sources Root` → ejecutar la clase `interfaz.Main`.

**Con los scripts:** `ejecutar.bat` (Windows) o `sh ejecutar.sh` (Linux/macOS). Compilan y ejecutan.

**A mano:**

```bash
javac -encoding UTF-8 -d out src/modelo/*.java src/negocio/*.java src/interfaz/*.java
java -cp out interfaz.Main
```

> Si los acentos se ven mal en la consola de Windows, ejecute antes `chcp 65001` (el script `ejecutar.bat` ya lo hace).

Al iniciar se cargan los 4 productos del caso con algo de stock. Los datos viven en memoria: al cerrar el programa se pierden.

## Menú y funcionalidades

| Opción | Funcionalidad | Qué hace |
|---|---|---|
| 1 | RF1 Registrar nuevo producto | Pide todos los datos; valida campos obligatorios, números, código único y que el stock inicial quepa. |
| 2 | RF2 Registrar recepción de mercadería | Solo lunes a viernes de 08:00 a 13:00; valida caducidad, espacio libre y presupuesto del mes. |
| 3 | RF3 Despachar pedido (FEFO) | Descuenta de los lotes que caducan antes; si no alcanza el stock, registra un quiebre. |
| 4 | RF4 Consultar inventario | Stock por producto y por lote, vencimientos, valor y ocupación de cada área. |
| 5 | RF5 Alertas y merma | Lista lotes vencidos o por vencer; permite retirar los vencidos y registrar la pérdida. |
| 6 | RF6 Clasificación ABC | Ordena por valor de consumo anual y asigna clase A, B o C. |
| 7 | RF7 Plan de reposición | Cuánto pedir de cada producto, cuándo (fecha de corte) y por qué esa cantidad. |
| 8 | RF8 Indicadores | Merma, quiebres, nivel de servicio, compras del mes y espacio usado. |
| 9 | Cambiar la fecha del sistema | Avanza el tiempo para simular caducidades, cortes de proveedores y picos de demanda. |

## Restricciones del caso que valida el sistema

| Restricción | Valor | Dónde se aplica |
|---|---|---|
| Presupuesto de reposición | $12,000 por mes, sin crédito | `GestorInventario.registrarIngreso` y `PlanificadorReposicion` |
| Espacio | 15 m³ de cámara fría, 40 m³ de estantería seca | `GestorInventario.validarEspacio` |
| Recepción de mercadería | Lunes a viernes, 08:00 a 13:00 | `GestorInventario.validarHorarioRecepcion` |
| Tiempos de entrega | 2 días hábiles (locales), 5 (nacional), 12 a 15 (importador) | `Proveedor` |
| Fechas de corte | Cada lunes (locales y nacional); día 1 de cada mes (importador) | `Proveedor.ReglaCorte` |
| Caducidad | Jugos 14 días, granola 45 días, barras 6 meses, proteína 18 meses | `ProductoPerecedero`, `ProductoNoPerecedero` |

## Cómo calcula el plan de reposición (RF7)

Como solo se puede pedir en las fechas de corte, un pedido tiene que alcanzar hasta que llegue el siguiente.

- **EOQ** = √(2 · D · S / H), con D = demanda anual, S = costo por pedido del proveedor y H = costo anual de mantener una unidad (almacenamiento más costo de capital).
- **Período de protección** P = días hasta el siguiente corte + tiempo de entrega (en días corridos: cada día hábil cuenta 7/5).
- **Stock de seguridad** = Z · √(P · σd² + d² · σL²), con Z según la clase ABC (A: 2.05, B: 1.65, C: 1.28).
- **Punto de reorden** = demanda esperada en P + stock de seguridad.
- **Regla:** en la fecha de corte, si el stock que habrá es menor o igual al punto de reorden, se pide el mayor entre el EOQ y lo necesario para llegar al punto de reorden. Esa cantidad se reduce si supera lo que se alcanza a vender dentro de la vida útil (80 %), el espacio libre del área o el presupuesto que queda en el mes del pedido.
- Los productos se evalúan en orden ABC, para que el presupuesto limitado vaya primero a los de clase A.
- La demanda sube 30 % en los primeros 5 días de cada mes y en enero y septiembre.

## Supuestos (no vienen del caso)

El caso no entrega estos datos, así que se asumieron. Están en `negocio/DatosIniciales.java` y se pueden cambiar.

| Dato | Valor asumido |
|---|---|
| Demanda diaria (desviación) | Jugo 85 (20), barras 3 (1.2), proteína 2 (0.8), granola 10 (4) |
| Volumen por unidad (m³) | Jugo 0.003, barras 0.004, proteína 0.006, granola 0.0045 |
| Costo por pedido | $12 (locales), $25 (nacional), $60 (importador) |
| Costo de capital | 18 % anual del costo del producto |
| Stock inicial | Jugo 60 + 120, barras 120, proteína 70, granola 25 + 40 (estos 40 ya vencidos, para mostrar alertas y merma) |

## Limitaciones

- No se modelan los pedidos que ya están en tránsito: el plan se calcula con el stock que hay en bodega.
- Los datos no se guardan en disco ni en base de datos.
- La interfaz es de consola.

## Cómo probarlo rápido

1. Opción **4**: se ven los lotes en orden de caducidad y uno vencido (granola).
2. Opción **2** con la hora `14:00` (o con la fecha del sistema en sábado o domingo): error de horario. Con una hora entre 08:00 y 13:00 en día hábil se registra; si hoy es fin de semana, use la opción **9** para avanzar a un lunes.
3. Opción **2** con la cantidad vacía: *"La cantidad recibida es obligatoria."*
4. Opción **3** pidiendo 150 jugos: se ve que usa primero el lote que caduca antes. Pidiendo más de lo disponible: quiebre de stock.
5. Opción **5**: retirar el lote vencido y luego ver la merma en la opción **8**.
6. Opción **7**: plan de reposición; después de registrar o despachar, el plan cambia.
7. Opción **1** con la cantidad inicial vacía: *"La cantidad inicial es obligatoria."*

## Uso de IA

Herramienta: Claude (Anthropic), como apoyo para escribir y probar el código. El prompt utilizado se indica en el informe técnico en PDF.
