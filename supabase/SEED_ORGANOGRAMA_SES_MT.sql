-- ============================================================
-- Alimentar organograma: Governo MT + Secretaria de Estado de Saúde (SES)
-- Baseado no Organograma.pdf - sem siglas
-- Execute no Supabase: SQL Editor > New query > Cole e Run
-- ============================================================

-- Garantir colunas sigla/descricao em unidades_hospitalares (se ainda não existirem)
alter table public.unidades_hospitalares
  add column if not exists sigla text,
  add column if not exists descricao text;

-- Limpar dados existentes (ordem por causa das FKs)
delete from public.setores;
delete from public.unidades_hospitalares;
delete from public.secretarias_adjuntas;
delete from public.secretarias;
delete from public.governo;

-- UUIDs fixos para referência
-- Governo
insert into public.governo (id, nome, sigla)
values ('11111111-1111-4111-a111-111111111111', 'Governo do Estado de Mato Grosso', null);

-- Secretaria (SES)
insert into public.secretarias (id, governo_id, nome, sigla, descricao)
values ('22222222-2222-4222-a222-222222222222', '11111111-1111-4111-a111-111111111111', 'Secretaria de Estado de Saúde', null, null);

-- Secretarias Adjuntas (Gabinetes do Secretário Adjunto)
insert into public.secretarias_adjuntas (id, secretaria_id, nome, sigla, descricao) values
('33333333-3333-4333-a333-333333333301', '22222222-2222-4222-a222-222222222222', 'Gabinete do Secretário Adjunto de Gestão Hospitalar', null, null),
('33333333-3333-4333-a333-333333333302', '22222222-2222-4222-a222-222222222222', 'Gabinete do Secretário Adjunto de Orçamento e Finanças', null, null),
('33333333-3333-4333-a333-333333333303', '22222222-2222-4222-a222-222222222222', 'Gabinete do Secretário Adjunto de Atenção e Vigilância em Saúde', null, null),
('33333333-3333-4333-a333-333333333304', '22222222-2222-4222-a222-222222222222', 'Gabinete do Secretário Adjunto Executivo de Saúde', null, null),
('33333333-3333-4333-a333-333333333305', '22222222-2222-4222-a222-222222222222', 'Gabinete do Secretário Adjunto de Unidades Especializadas', null, null),
('33333333-3333-4333-a333-333333333306', '22222222-2222-4222-a222-222222222222', 'Gabinete do Secretário Adjunto do Complexo Regulador', null, null),
('33333333-3333-4333-a333-333333333307', '22222222-2222-4222-a222-222222222222', 'Gabinete do Secretário Adjunto de Administração Sistêmica', null, null),
('33333333-3333-4333-a333-333333333308', '22222222-2222-4222-a222-222222222222', 'Gabinete do Secretário Adjunto de Aquisições e Contratos', null, null),
('33333333-3333-4333-a333-333333333309', '22222222-2222-4222-a222-222222222222', 'Gabinete do Secretário Adjunto de Infraestrutura e Tecnologia da Informação', null, null);

-- Unidades Hospitalares / Unidades sob a SES (hospitais regionais, estaduais, ERS, centros)
insert into public.unidades_hospitalares (id, secretaria_id, nome, sigla, descricao) values
('44444444-4444-4444-a444-444444444401', '22222222-2222-4222-a222-222222222222', 'Hospital Regional de Rondonópolis "Irmã Elza Giovanella"', null, null),
('44444444-4444-4444-a444-444444444402', '22222222-2222-4222-a222-222222222222', 'Hospital Regional de Sorriso', null, null),
('44444444-4444-4444-a444-444444444403', '22222222-2222-4222-a222-222222222222', 'Hospital Regional de Cáceres "Doutor Antonio Carlos Souto Fontes"', null, null),
('44444444-4444-4444-a444-444444444404', '22222222-2222-4222-a222-222222222222', 'Hospital Regional de Colíder', null, null),
('44444444-4444-4444-a444-444444444405', '22222222-2222-4222-a222-222222222222', 'Hospital Regional de Alta Floresta "Albert Sabin"', null, null),
('44444444-4444-4444-a444-444444444406', '22222222-2222-4222-a222-222222222222', 'Hospital Regional de Sinop', null, null),
('44444444-4444-4444-a444-444444444407', '22222222-2222-4222-a222-222222222222', 'Hospital Estadual "Lousite Ferreira da Silva"', null, null),
('44444444-4444-4444-a444-444444444408', '22222222-2222-4222-a222-222222222222', 'Hospital Estadual Santa Casa', null, null),
('44444444-4444-4444-a444-444444444409', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Água Boa', null, null),
('44444444-4444-4444-a444-444444444410', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Alta Floresta', null, null),
('44444444-4444-4444-a444-444444444411', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde da Baixada Cuiabana', null, null),
('44444444-4444-4444-a444-444444444412', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Barra do Garças', null, null),
('44444444-4444-4444-a444-444444444413', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Cáceres', null, null),
('44444444-4444-4444-a444-444444444414', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Colíder', null, null),
('44444444-4444-4444-a444-444444444415', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Diamantino', null, null),
('44444444-4444-4444-a444-444444444416', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Juara', null, null),
('44444444-4444-4444-a444-444444444417', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Juína', null, null),
('44444444-4444-4444-a444-444444444418', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Peixoto de Azevedo', null, null),
('44444444-4444-4444-a444-444444444419', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Pontes e Lacerda', null, null),
('44444444-4444-4444-a444-444444444420', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Porto Alegre do Norte', null, null),
('44444444-4444-4444-a444-444444444421', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de São Félix do Araguaia', null, null),
('44444444-4444-4444-a444-444444444422', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Sinop', null, null),
('44444444-4444-4444-a444-444444444423', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Tangará da Serra', null, null),
('44444444-4444-4444-a444-444444444424', '22222222-2222-4222-a222-222222222222', 'Escritório Regional de Saúde de Rondonópolis', null, null),
('44444444-4444-4444-a444-444444444425', '22222222-2222-4222-a222-222222222222', 'MT - Hemocentro', null, null),
('44444444-4444-4444-a444-444444444426', '22222222-2222-4222-a222-222222222222', 'Centro Estadual de Referência de Média e Alta Complexidades de Mato Grosso - CERMAC', null, null),
('44444444-4444-4444-a444-444444444427', '22222222-2222-4222-a222-222222222222', 'Centro de Reabilitação Integral Dom Aquino Corrêa do SUS - CRIDAC / CER III', null, null),
('44444444-4444-4444-a444-444444444428', '22222222-2222-4222-a222-222222222222', 'Centro Estadual de Odontologia para Pacientes Especiais - CEOPE', null, null),
('44444444-4444-4444-a444-444444444429', '22222222-2222-4222-a222-222222222222', 'Laboratório Central de Saúde Pública do Estado de Mato Grosso - LACEN/MT', null, null),
('44444444-4444-4444-a444-444444444430', '22222222-2222-4222-a222-222222222222', 'Escola de Saúde Pública do Estado de Mato Grosso - ESP/MT', null, null),
('44444444-4444-4444-a444-444444444431', '22222222-2222-4222-a222-222222222222', 'Centro Integrado de Atenção Psicossocial Adauto Botelho - CIAPS', null, null);

-- Setores sob a Adjunta "Gestão Hospitalar" (exemplos)
insert into public.setores (id, nome, sigla, descricao, secretaria_adjunta_id, unidade_hospitalar_id) values
('55555555-5555-4555-a555-555555555501', 'Superintendência de Gestão e Acompanhamento de Serviços Hospitalares', null, null, '33333333-3333-4333-a333-333333333301', null),
('55555555-5555-4555-a555-555555555502', 'Superintendência Administrativa e Financeira', null, null, '33333333-3333-4333-a333-333333333301', null),
('55555555-5555-4555-a555-555555555503', 'Superintendência de Enfermagem', null, null, '33333333-3333-4333-a333-333333333301', null),
('55555555-5555-4555-a555-555555555504', 'Coordenadoria de Gestão e Organização de Serviços', null, null, '33333333-3333-4333-a333-333333333301', null),
('55555555-5555-4555-a555-555555555505', 'Coordenadoria de Acompanhamento da Execução Administrativa, Contábil e Financeira', null, null, '33333333-3333-4333-a333-333333333301', null);

-- Setores sob a Adjunta "Orçamento e Finanças"
insert into public.setores (id, nome, sigla, descricao, secretaria_adjunta_id, unidade_hospitalar_id) values
('55555555-5555-4555-a555-555555555511', 'Superintendência de Orçamento', null, null, '33333333-3333-4333-a333-333333333302', null),
('55555555-5555-4555-a555-555555555512', 'Superintendência de Finanças', null, null, '33333333-3333-4333-a333-333333333302', null),
('55555555-5555-4555-a555-555555555513', 'Superintendência de Contabilidade', null, null, '33333333-3333-4333-a333-333333333302', null),
('55555555-5555-4555-a555-555555555514', 'Coordenadoria de Execução Orçamentária', null, null, '33333333-3333-4333-a333-333333333302', null),
('55555555-5555-4555-a555-555555555515', 'Coordenadoria de Convênios', null, null, '33333333-3333-4333-a333-333333333302', null),
('55555555-5555-4555-a555-555555555516', 'Coordenadoria da Receita', null, null, '33333333-3333-4333-a333-333333333302', null),
('55555555-5555-4555-a555-555555555517', 'Coordenadoria de Execução Financeira', null, null, '33333333-3333-4333-a333-333333333302', null),
('55555555-5555-4555-a555-555555555518', 'Coordenadoria Contábil', null, null, '33333333-3333-4333-a333-333333333302', null),
('55555555-5555-4555-a555-555555555519', 'Coordenadoria de Prestação de Contas', null, null, '33333333-3333-4333-a333-333333333302', null);

-- Setores sob a Adjunta "Atenção e Vigilância em Saúde"
insert into public.setores (id, nome, sigla, descricao, secretaria_adjunta_id, unidade_hospitalar_id) values
('55555555-5555-4555-a555-555555555521', 'Superintendência de Vigilância em Saúde', null, null, '33333333-3333-4333-a333-333333333303', null),
('55555555-5555-4555-a555-555555555522', 'Superintendência de Atenção à Saúde', null, null, '33333333-3333-4333-a333-333333333303', null),
('55555555-5555-4555-a555-555555555523', 'Coordenadoria do Programa Estadual de Imunização', null, null, '33333333-3333-4333-a333-333333333303', null),
('55555555-5555-4555-a555-555555555524', 'Coordenadoria de Vigilância Sanitária', null, null, '33333333-3333-4333-a333-333333333303', null),
('55555555-5555-4555-a555-555555555525', 'Coordenadoria de Vigilância Epidemiológica', null, null, '33333333-3333-4333-a333-333333333303', null),
('55555555-5555-4555-a555-555555555526', 'Coordenadoria de Vigilância em Saúde Ambiental', null, null, '33333333-3333-4333-a333-333333333303', null),
('55555555-5555-4555-a555-555555555527', 'Coordenadoria de Vigilância em Saúde do Trabalhador', null, null, '33333333-3333-4333-a333-333333333303', null),
('55555555-5555-4555-a555-555555555528', 'Coordenadoria de Atenção Primária', null, null, '33333333-3333-4333-a333-333333333303', null),
('55555555-5555-4555-a555-555555555529', 'Coordenadoria de Organização de Redes de Atenção à Saúde', null, null, '33333333-3333-4333-a333-333333333303', null),
('55555555-5555-4555-a555-555555555530', 'Coordenadoria de Atenção Terciária', null, null, '33333333-3333-4333-a333-333333333303', null);

-- Setores sob a Adjunta "Administração Sistêmica"
insert into public.setores (id, nome, sigla, descricao, secretaria_adjunta_id, unidade_hospitalar_id) values
('55555555-5555-4555-a555-555555555541', 'Superintendência de Gestão de Pessoas', null, null, '33333333-3333-4333-a333-333333333307', null),
('55555555-5555-4555-a555-555555555542', 'Superintendência Administrativa', null, null, '33333333-3333-4333-a333-333333333307', null),
('55555555-5555-4555-a555-555555555543', 'Coordenadoria de Provimento e Movimentação de Pessoal', null, null, '33333333-3333-4333-a333-333333333307', null),
('55555555-5555-4555-a555-555555555544', 'Coordenadoria de Saúde e Segurança no Trabalho', null, null, '33333333-3333-4333-a333-333333333307', null),
('55555555-5555-4555-a555-555555555545', 'Coordenadoria de Apoio Logístico', null, null, '33333333-3333-4333-a333-333333333307', null),
('55555555-5555-4555-a555-555555555546', 'Coordenadoria de Transportes', null, null, '33333333-3333-4333-a333-333333333307', null),
('55555555-5555-4555-a555-555555555547', 'Coordenadoria de Protocolo e Arquivo', null, null, '33333333-3333-4333-a333-333333333307', null),
('55555555-5555-4555-a555-555555555548', 'Coordenadoria de Patrimônio', null, null, '33333333-3333-4333-a333-333333333307', null),
('55555555-5555-4555-a555-555555555549', 'Coordenadoria de Materiais', null, null, '33333333-3333-4333-a333-333333333307', null);

-- Setores sob a Adjunta "Aquisições e Contratos"
insert into public.setores (id, nome, sigla, descricao, secretaria_adjunta_id, unidade_hospitalar_id) values
('55555555-5555-4555-a555-555555555551', 'Superintendência de Aquisições e Contratos', null, null, '33333333-3333-4333-a333-333333333308', null),
('55555555-5555-4555-a555-555555555552', 'Superintendência de Obras, Reformas e Manutenção', null, null, '33333333-3333-4333-a333-333333333308', null),
('55555555-5555-4555-a555-555555555553', 'Superintendência de Tecnologia da Informação', null, null, '33333333-3333-4333-a333-333333333308', null),
('55555555-5555-4555-a555-555555555554', 'Coordenadoria de Aquisições', null, null, '33333333-3333-4333-a333-333333333308', null),
('55555555-5555-4555-a555-555555555555', 'Coordenadoria de Contratos', null, null, '33333333-3333-4333-a333-333333333308', null),
('55555555-5555-4555-a555-555555555556', 'Coordenadoria de Fiscalização', null, null, '33333333-3333-4333-a333-333333333308', null),
('55555555-5555-4555-a555-555555555557', 'Coordenadoria de Infraestrutura de TI', null, null, '33333333-3333-4333-a333-333333333308', null),
('55555555-5555-4555-a555-555555555558', 'Coordenadoria de Assistência Técnica e Suporte à Usuários de TI', null, null, '33333333-3333-4333-a333-333333333308', null);

-- Setores sob o Gabinete do Secretário (raiz da SES) - Unidade Jurídica, etc. (vinculamos à primeira adjunta como exemplo)
insert into public.setores (id, nome, sigla, descricao, secretaria_adjunta_id, unidade_hospitalar_id) values
('55555555-5555-4555-a555-555555555561', 'Unidade Jurídica', null, null, '33333333-3333-4333-a333-333333333304', null),
('55555555-5555-4555-a555-555555555562', 'Unidade Setorial de Controle Interno - UNISECI', null, null, '33333333-3333-4333-a333-333333333304', null),
('55555555-5555-4555-a555-555555555563', 'Núcleo de Gestão Estratégica para Resultados - NGER', null, null, '33333333-3333-4333-a333-333333333304', null),
('55555555-5555-4555-a555-555555555564', 'Comissão de Ética', null, null, '33333333-3333-4333-a333-333333333304', null),
('55555555-5555-4555-a555-555555555565', 'Unidade de Assessoria', null, null, '33333333-3333-4333-a333-333333333304', null),
('55555555-5555-4555-a555-555555555566', 'Conferência Estadual de Saúde', null, null, '33333333-3333-4333-a333-333333333304', null),
('55555555-5555-4555-a555-555555555567', 'Conselho Estadual de Saúde', null, null, '33333333-3333-4333-a333-333333333304', null),
('55555555-5555-4555-a555-555555555568', 'Ouvidoria Setorial de Saúde', null, null, '33333333-3333-4333-a333-333333333304', null);

-- Setores sob Unidade Hospitalar (exemplo: Hospital Regional de Rondonópolis)
insert into public.setores (id, nome, sigla, descricao, secretaria_adjunta_id, unidade_hospitalar_id) values
('55555555-5555-4555-a555-555555555571', 'Coordenadoria de Enfermagem Cirúrgica e CME', null, null, null, '44444444-4444-4444-a444-444444444401'),
('55555555-5555-4555-a555-555555555572', 'Coordenadoria de Urgência e Emergência', null, null, null, '44444444-4444-4444-a444-444444444401'),
('55555555-5555-4555-a555-555555555573', 'Coordenadoria de Medicina Intensiva', null, null, null, '44444444-4444-4444-a444-444444444401'),
('55555555-5555-4555-a555-555555555574', 'Coordenadoria de Clínica Médica e Pediátrica', null, null, null, '44444444-4444-4444-a444-444444444401'),
('55555555-5555-4555-a555-555555555575', 'Superintendência Administrativa e Financeira', null, null, null, '44444444-4444-4444-a444-444444444401');
