/**
 * Configuração do Supabase
 * 
 * Este arquivo contém SOMENTE a chave pública do Supabase.
 * NUNCA inclua service_role key ou secret key aqui.
 * 
 * Como configurar:
 * 1. Acesse https://app.supabase.com
 * 2. Selecione seu projeto
 * 3. Vá para Settings > API
 * 4. Copie a URL (Project URL) e a chave pública (anon public key)
 * 5. Substitua os valores abaixo
 */

window.SUPABASE_CONFIG = {
  // Substitua pela sua URL do Supabase (ex: https://seu-projeto.supabase.co)
  URL: 'https://YOUR_PROJECT_ID.supabase.co',
  
  // Substitua pela sua chave pública do Supabase (anon key)
  // NÃO use service_role key ou secret key aqui!
  PUBLISHABLE_KEY: 'YOUR_ANON_PUBLIC_KEY'
};

// Validação: certificar que as chaves foram configuradas
if (window.SUPABASE_CONFIG.URL === 'https://YOUR_PROJECT_ID.supabase.co' || 
    window.SUPABASE_CONFIG.PUBLISHABLE_KEY === 'YOUR_ANON_PUBLIC_KEY') {
  console.warn('⚠️ Supabase não está configurado. Configure supabase-config.js com suas credenciais.');
  window.SUPABASE_CONFIG.CONFIGURED = false;
} else {
  window.SUPABASE_CONFIG.CONFIGURED = true;
  console.log('✓ Supabase configurado com sucesso.');
}
