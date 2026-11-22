// 1) Crie um projeto em https://supabase.com
// 2) Copie Project URL e anon/public key em Supabase > Project Settings > API
// 3) Preencha os valores abaixo. Nunca coloque a service_role key no navegador.
const SUPABASE_URL = 'https://qgocbamgjahcnwabpdgo.supabase.co/rest/v1/';
const SUPABASE_ANON_KEY = 'SENHA_SUPLA';

const supabaseConfigured = SUPABASE_URL.startsWith('https://') && !SUPABASE_URL.includes('COLE_AQUI') && !SUPABASE_ANON_KEY.includes('COLE_AQUI');
const supabaseClient = supabaseConfigured
  ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;
