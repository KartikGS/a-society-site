import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://a-society.dev',
  integrations: [
    starlight({
      title: 'A-Society',
      description: 'An agentic harness for any project: structured memory, role-based workflows, self-improvement, and cross-project feedback.',
      logo: {
        src: './src/assets/logo.svg',
        replacesTitle: false,
      },
      social: {
        github: 'https://github.com/KartikGS/a-society',
      },
      sidebar: [
        { label: 'Getting Started', link: '/docs/getting-started' },
        { label: 'Runtime Guide', link: '/docs/runtime-guide' },
        { label: 'Model Configuration', link: '/docs/model-configuration' },
        { label: 'Concepts', link: '/docs/concepts' },
        {
          label: 'Internals',
          items: [
            { label: 'Architecture', link: '/internals/architecture' },
            { label: 'Flow State', link: '/internals/flow-state' },
            { label: 'Role Sessions', link: '/internals/role-sessions' },
          ],
        },
      ],
      customCss: ['./src/styles/starlight-custom.css'],
      favicon: '/favicon.svg',
      head: [
        {
          tag: 'link',
          attrs: {
            rel: 'preconnect',
            href: 'https://fonts.googleapis.com',
          },
        },
        {
          tag: 'link',
          attrs: {
            rel: 'preconnect',
            href: 'https://fonts.gstatic.com',
            crossorigin: '',
          },
        },
        {
          tag: 'link',
          attrs: {
            href: 'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap',
            rel: 'stylesheet',
          },
        },
      ],
      defaultLocale: 'root',
      locales: {
        root: { label: 'English', lang: 'en' },
      },
    }),
  ],
});
