# 🧠 Base de Datos NoSQL: Sintaxis de Operadores en MongoDB

Este repositorio contiene una base de datos MongoDB llamada `sintaxis_operadoresDB`, que almacena información útil sobre:

- Operadores **de comparación** y **lógicos**
- Ejemplos de **combinaciones** entre operadores
- Sintaxis para consulta y uso en MongoDB

---

## 🔄 Restaurar la Base de Datos

### 🛠 Requisitos

- Tener MongoDB Community instalado:  
  👉 [https://www.mongodb.com/try/download/community](https://www.mongodb.com/try/download/community)

- Tener activo el servicio de MongoDB
- Tener `mongorestore` disponible en el sistema

### ▶️ Comando de restauración

```bash
mongorestore --drop --db=sintaxis_operadoresDB dump/sintaxis_operadoresDB
```
---

## 🌐 Consultas Disponibles

Una vez restaurada la base, abre <kbd>mongosh</kbd> y conéctate a la base de datos:

```js
use sintaxis_operadoresDB
```
### 📂 1. Colección operators

#### Ver todos los operadores
```js
db.operators.find({}, { _id: 0 }).pretty()
```
#### Buscar un operador por símbolo
```js
db.operators.findOne({ symbol: "&&" })
```
#### Filtrar por tipo: lógico o de comparación
```js
db.operators.find({ type: "logical" }, { symbol:1, example:1, _id:0 }).pretty()
```
### 🔀 2. Colección combinations

#### Ver todas las combinaciones
```js
db.combinations.find({}, { template: 1, _id: 0 }).pretty()
```

#### Todas las plantillas que incluyan un simbolo especificado (&)
```js
db.combinations.find(
  { operators: "&&" },
  { template:1, _id:0 }
).pretty()
```
#### Todas las plantillas que incluyan simbolos especificados (|| y >=)
```js
db.combinations.find(
  { operators: { $all: ["||", ">="] } },
  { template:1, _id:0 }
).pretty()
```
#### Todas las plantillas que incluyan alguno de los simbolos especificados (! o <)
```js
db.combinations.find(
  { operators: { $in: ["!", "<"] } },
  { template:1, _id:0 }
).pretty()
```




---

### 📌 Ejemplos de documentos

#### 📄 operators

```json
{
  "symbol": "==",
  "type": "comparison",
  "description": "Compara si dos valores son iguales.",
  "syntax": "{ campo: { $eq: valor } }"
}
```

```json
{
  "symbol": "&&",
  "type": "logical",
  "description": "Evalúa si dos condiciones son verdaderas.",
  "syntax": "{ $and: [cond1, cond2] }"
}
```

#### 📄 combinations

```json
{
  "template": "{ edad: { $gte: 18 }, activo: true }",
  "operators": [">=", "=="]
}
```

```json
{
  "template": "{ $and: [ { salario: { $gt: 1000 } }, { edad: { $lte: 50 } } ] }",
  "operators": ["&&", ">", "<="]
}
```

---



