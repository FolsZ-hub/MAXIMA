/**
 * Firebase Admin SDK Initialization
 *
 * Supports two configuration modes:
 *   1. Service account JSON file (FIREBASE_SERVICE_ACCOUNT_PATH)
 *   2. Inline credentials via individual env vars
 *
 * Exports the initialized admin instance and a Firestore db reference.
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

/**
 * Build the Firebase credential from environment variables.
 * @returns {admin.credential.Credential}
 */
function buildCredential() {
  // Option 1: service account key file
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (serviceAccountPath) {
    const resolvedPath = path.resolve(serviceAccountPath);

    if (fs.existsSync(resolvedPath)) {
      const serviceAccount = require(resolvedPath);
      console.log('[Firebase] Inicializado con archivo de cuenta de servicio.');
      return admin.credential.cert(serviceAccount);
    }

    console.warn(
      `[Firebase] El archivo de cuenta de servicio no existe: ${resolvedPath}. ` +
        'Intentando con variables de entorno individuales...'
    );
  }

  // Option 2: inline credentials
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (projectId && clientEmail && privateKey) {
    console.log('[Firebase] Inicializado con credenciales en variables de entorno.');
    return admin.credential.cert({
      projectId,
      clientEmail,
      // Private key comes escaped in .env; replace literal \n with real newlines
      privateKey: privateKey.replace(/\\n/g, '\n'),
    });
  }

  // Fallback: application default credentials (useful in GCP environments)
  console.warn(
    '[Firebase] No se encontraron credenciales explicitas. ' +
      'Usando Application Default Credentials.'
  );
  return admin.credential.applicationDefault();
}

// Initialize the Firebase app (only once)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: buildCredential(),
    databaseURL: process.env.FIREBASE_DATABASE_URL || undefined,
  });
}

// Firestore reference
const db = admin.firestore();

module.exports = { admin, db };
