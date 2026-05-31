import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  integrations: [
    starlight({
      title: 'KURI',
      logo: { src: './src/assets/kuri-seal.svg', alt: 'Kuri seal' },
      customCss: ['./src/styles/grimoire.css'],
      components: {
        Header: './src/components/Header.astro',
      },
      defaultLocale: 'root',
      locales: {
        root: { label: 'English', lang: 'en' },
        fr:   { label: 'Français', lang: 'fr' },
      },
      head: [
        { tag: 'link', attrs: { rel: 'preconnect', href: 'https://fonts.googleapis.com' } },
        { tag: 'link', attrs: { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: true } },
        { tag: 'link', attrs: { rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Cinzel:wght@500;600;700&family=Cinzel+Decorative:wght@700;900&family=UnifrakturCook:wght@700&family=EB+Garamond:ital,wght@0,400;0,500;0,600;1,400&family=JetBrains+Mono:wght@400;500&display=swap' } },
        { tag: 'script', attrs: { src: '/grimoire-fx.js', defer: true } },
      ],
      expressiveCode: {
        themes: ['github-dark', 'github-dark'],
        styleOverrides: { borderRadius: '0px' },
      },
      sidebar: [
        {
          label: 'Codex Mechanica',
          translations: { fr: 'Codex Mechanica' },
          items: [
            {
              label: 'The Catechism',
              translations: { fr: 'La Catéchèse' },
              slug: 'introduction',
            },
            {
              label: 'Sacred Geometry',
              translations: { fr: 'Géométrie Sacrée' },
              autogenerate: { directory: 'architecture' },
            },
          ],
        },
        {
          label: 'Machine-Shrines',
          translations: { fr: 'Sanctuaires-Machines' },
          items: [
            {
              label: 'exampleHost',
              translations: { fr: 'exampleHost' },
              autogenerate: { directory: 'examplehost' },
            },
            {
              label: 'clochette',
              translations: { fr: 'clochette' },
              autogenerate: { directory: 'clochette' },
            },
            {
              label: 'RogueLeader',
              translations: { fr: 'RogueLeader' },
              autogenerate: { directory: 'rogueleader' },
            },
          ],
        },
        {
          label: 'Rites Opérationnels',
          translations: { fr: 'Rites Opérationnels' },
          autogenerate: { directory: 'operations' },
        },
      ],
    }),
  ],
});
