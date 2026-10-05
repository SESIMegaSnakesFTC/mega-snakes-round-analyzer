/**
 * Configuração do Supabase
 * 
 * Este arquivo contém SOMENTE a chave pública do Supabase.
 * NUNCA inclua service_role key ou secret key aqui.
 */

window.SUPABASE_CONFIG = {
  // URL do Supabase (Project URL)
  URL: 'https://flrnisqsqctfyvedjwnn.supabase.co',
  
  // Chave pública do Supabase (anon key)
  // NÃO use service_role key ou secret key aqui!
  PUBLISHABLE_KEY: 'sb_publishable_ioGfXG7nUrFwZGAYYVwWKw_LD_BeJbV'
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
