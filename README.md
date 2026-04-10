# TaskLedger

## Tutorial: como inserir os dados do Firebase

Esta aplicação inicia o Firebase diretamente no arquivo [`lib/main.dart`](/d:/Desenvolvimento%20para%20Dispositivos%20M%C3%B3veis%202/Projetos/appcrud/lib/main.dart#L1). Para conectar o projeto ao seu próprio Firebase, substitua os valores que estão dentro de `FirebaseOptions(...)` pelos dados do seu projeto.

### 1. Crie ou abra um projeto no Firebase

1. Acesse o [Firebase Console](https://console.firebase.google.com/).
2. Crie um projeto novo ou selecione um projeto existente.
3. Ative os serviços usados pela aplicação:
   - `Authentication`
   - `Cloud Firestore`

### 2. Registre seu app no Firebase

No Firebase Console, adicione um app para a plataforma que você vai testar. Depois disso, copie os dados de configuração exibidos pelo Firebase.

Os campos usados atualmente no projeto são:

- `apiKey`
- `authDomain`
- `projectId`
- `storageBucket`
- `messagingSenderId`
- `appId`

### 3. Abra o arquivo correto no projeto

Edite o arquivo [`lib/main.dart`](/d:/Desenvolvimento%20para%20Dispositivos%20M%C3%B3veis%202/Projetos/appcrud/lib/main.dart#L8).

Hoje a configuração está neste formato:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "SUA_API_KEY",
    authDomain: "SEU_AUTH_DOMAIN",
    projectId: "SEU_PROJECT_ID",
    storageBucket: "SEU_STORAGE_BUCKET",
    messagingSenderId: "SEU_MESSAGING_SENDER_ID",
    appId: "SEU_APP_ID",
  ),
);
```

Substitua cada valor pelos dados do seu projeto Firebase.

### 4. Exemplo de onde inserir os dados

Use este modelo:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "COLE_AQUI_SUA_API_KEY",
      authDomain: "COLE_AQUI_SEU_AUTH_DOMAIN",
      projectId: "COLE_AQUI_SEU_PROJECT_ID",
      storageBucket: "COLE_AQUI_SEU_STORAGE_BUCKET",
      messagingSenderId: "COLE_AQUI_SEU_MESSAGING_SENDER_ID",
      appId: "COLE_AQUI_SEU_APP_ID",
    ),
  );

  runApp(const TaskLedgerApp());
}
```

### 5. Configure o Firebase para o que o app usa

Além da inicialização, a aplicação depende destes recursos:

- `Firebase Authentication` para cadastro, login e recuperação de usuário.
- `Cloud Firestore` para salvar dados de perfil, tarefas e transações financeiras.

Se esses serviços não estiverem ativados no seu projeto, o app não conseguirá funcionar corretamente.

### 6. Rode o projeto

```bash
flutter pub get
flutter run
```

## Sobre a aplicação

O `TaskLedger` é um aplicativo Flutter para organização pessoal, reunindo gerenciamento de tarefas e controle financeiro em uma única interface. O projeto utiliza Firebase para autenticação de usuários e persistência de dados na nuvem.

## Funcionalidades principais

- Cadastro e login de usuários com `Firebase Authentication`
- Armazenamento de dados do usuário no `Cloud Firestore`
- Controle de tarefas
- Controle financeiro com receitas e despesas
- Filtros por tipo de transação e período
- Edição e exclusão de lançamentos financeiros

## Estrutura principal

- [`lib/main.dart`](/d:/Desenvolvimento%20para%20Dispositivos%20M%C3%B3veis%202/Projetos/appcrud/lib/main.dart): inicialização do Flutter e do Firebase
- [`lib/screens/home.dart`](/d:/Desenvolvimento%20para%20Dispositivos%20M%C3%B3veis%202/Projetos/appcrud/lib/screens/home.dart): tela inicial
- [`lib/screens/tela_cadastro.dart`](/d:/Desenvolvimento%20para%20Dispositivos%20M%C3%B3veis%202/Projetos/appcrud/lib/screens/tela_cadastro.dart): cadastro de usuário
- [`lib/screens/tela_financas.dart`](/d:/Desenvolvimento%20para%20Dispositivos%20M%C3%B3veis%202/Projetos/appcrud/lib/screens/tela_financas.dart): módulo financeiro

## Tecnologias utilizadas

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore

## Observação

Atualmente, a configuração do Firebase está escrita manualmente em [`lib/main.dart`](/d:/Desenvolvimento%20para%20Dispositivos%20M%C3%B3veis%202/Projetos/appcrud/lib/main.dart#L8). Se quiser uma estrutura mais adequada para múltiplas plataformas, o próximo passo recomendado é gerar um arquivo `firebase_options.dart` com o `FlutterFire CLI`.
