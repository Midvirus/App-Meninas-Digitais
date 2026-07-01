# 🚀 App Meninas Digitais


O **App Meninas Digitais** é uma aplicação Full Stack desenvolvida com foco no fortalecimento da presença feminina na área da tecnologia.  
O projeto reúne um aplicativo multiplataforma em Flutter e uma API REST robusta em Spring Boot, proporcionando uma experiência moderna, segura e escalável.

---

## 🌐 Demonstração Online

🔗 Acesse a demonstração:  
https://midvirus.github.io/App-Meninas-Digitais/

### 🔑 Acesso para Teste
**ADMIN**
- **E-mail:** `admin@gmail.com`
- **Senha:** `12345`
**TUTOR**
- **E-mail:** `teste@gmail.com`
- **Senha:** `12345`
**TUTORANDA**
- **E-mail:** `aluna@gmail.com`
- **Senha:** `12345`

---
# Video de Execulção do projeto
[Video de como execultar o programa](https://drive.google.com/drive/folders/1K6p9C9GPt0hRtWzt8rWcga_15YD9NS3j)

# 📁 Estrutura do Projeto

```bash
App-Meninas-Digitais/
│
├── frontend/
│   └── Aplicativo Flutter multiplataforma responsável pela interface do usuário,
│       navegação, integração com Supabase e funcionalidades do app.
│
└── backend/
    └── API REST desenvolvida com Spring Boot, responsável pela autenticação,
            regras de negócio, persistência de dados e documentação Swagger.
```

---

# 🛠️ Tecnologias Utilizadas

## 🎨 Frontend
- Flutter
- Dart
- Supabase
- Font Awesome Flutter
- URL Launcher

## ⚙️ Backend
- Java 21
- Spring Boot 3
- Maven
- PostgreSQL
- Spring Security
- JWT Authentication
- Swagger/OpenAPI

---

# 📥 Clonando o Repositório

```bash
git clone https://github.com/MidVirus/app-meninas-digitais.git
```

---

# ⚙️ Configuração do Backend

## ✅ Pré-requisitos
Antes de executar o backend, certifique-se de possuir instalado:

- JDK 21
- Maven
- PostgreSQL

## ▶️ Executando o Backend

Acesse a pasta do projeto backend:

```bash
cd backend/meninas-digitais-backend
```

Execute a aplicação Spring Boot:

```bash
./mvnw spring-boot:run
```

Ou no Windows:

```bash
mvnw spring-boot:run
```

---

# 📱 Configuração do Frontend

## ✅ Pré-requisitos

Para instalar o Flutter corretamente em seu ambiente, siga a documentação oficial:

🔗 https://docs.flutter.dev/get-started/install

## ▶️ Executando o Frontend

Acesse a pasta do frontend:

```bash
cd frontend
```

Instale as dependências:

```bash
flutter pub get
```

Execute o aplicativo:

```bash
flutter run
```

---

# 🔐 Segurança e Autenticação

O backend utiliza:

- Spring Security
- Autenticação via JWT
- Controle de acesso baseado em tokens
- Proteção de endpoints REST

---
