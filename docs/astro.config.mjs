import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

const base = '/nixos';

export default defineConfig({
  site: 'https://gfriloux.github.io',
  base,
  integrations: [
    starlight({
      title: 'KURI',
      logo: { src: './src/assets/kuri-emblem.png', alt: 'Kuri seal' },
      favicon: '/favicon.png',
      customCss: ['./src/styles/logbook.css'],
      components: {
        Header: './src/components/Header.astro',
      },
      defaultLocale: 'root',
      locales: {
        root: { label: 'English', lang: 'en' },
        fr:   { label: 'Français', lang: 'fr' },
      },
      head: [
        { tag: 'link', attrs: { rel: 'icon', href: `${base}/favicon.ico`, sizes: '32x32' } },
        { tag: 'link', attrs: { rel: 'apple-touch-icon', href: `${base}/apple-touch-icon.png` } },
        { tag: 'link', attrs: { rel: 'preconnect', href: 'https://fonts.googleapis.com' } },
        { tag: 'link', attrs: { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: true } },
        { tag: 'link', attrs: { rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@600;700&family=Spectral:ital,wght@0,400;0,600;1,400&family=IBM+Plex+Mono:wght@400;500&display=swap' } },
      ],
      expressiveCode: {
        themes: ['github-dark', 'github-light'],
        styleOverrides: { borderRadius: '0px' },
      },
      sidebar: [
        {
          label: 'Start',
          translations: { fr: 'Démarrer' },
          items: [
            {
              label: 'Introduction',
              translations: { fr: 'Introduction' },
              slug: 'introduction',
            },
            {
              label: 'Architecture',
              translations: { fr: 'Architecture' },
              items: [{ autogenerate: { directory: 'architecture' } }],
            },
          ],
        },
        {
          label: 'Hosts',
          translations: { fr: 'Machines' },
          items: [
            {
              label: 'exampleHost',
              translations: { fr: 'exampleHost' },
              items: [{ autogenerate: { directory: 'examplehost' } }],
            },
            {
              label: 'clochette',
              translations: { fr: 'clochette' },
              items: [{ autogenerate: { directory: 'clochette' } }],
            },
            {
              label: 'RogueLeader',
              translations: { fr: 'RogueLeader' },
              items: [{ autogenerate: { directory: 'rogueleader' } }],
            },
            {
              label: 'skitarii',
              translations: { fr: 'skitarii' },
              items: [{ autogenerate: { directory: 'skitarii' } }],
            },
          ],
        },
        {
          label: 'Operations',
          translations: { fr: 'Exploitation' },
          items: [{ autogenerate: { directory: 'operations' } }],
        },
      ],
    }),
  ],
});
