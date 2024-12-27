// .eslintrc.js
const config = {
  root: true,
  env: {
    node: true,
    es6: true,
    browser: true,
    amd: true,
    commonjs: true,
  },
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
  extends: ["eslint:recommended", "google"],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    quotes: ["error", "double", { allowTemplateLiterals: true }],
  },
  ignorePatterns: ["node_modules/", "lib/", "/lib/**/*"],
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {
        "@typescript-eslint/no-require-imports": "off",
        quotes: ["error", "double"],
        "import/no-unresolved": 0,
      },
    },
  ],
  globals: { window: true, module: true },
};

export default config;
