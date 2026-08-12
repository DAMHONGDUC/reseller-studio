module.exports = {
  root: true,
  env: { es2022: true, node: true },
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: ['tsconfig.json'],
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  ignorePatterns: ['lib/**/*', '.eslintrc.js'],
  rules: {
    quotes: ['error', 'single'],
    'comma-dangle': ['error', 'always-multiline'],
    // A caught error that is not logged is invisible by construction — the
    // same rule the Dart side follows.
    'no-empty': ['error', { allowEmptyCatch: false }],
  },
};
