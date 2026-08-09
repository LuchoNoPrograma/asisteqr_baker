{{flutter_js}}
{{flutter_build_config}}

const loading = document.getElementById('app-loading');
const legacyWorkerCleanup = 'serviceWorker' in navigator
  ? navigator.serviceWorker
      .getRegistrations()
      .then((registrations) =>
        Promise.all(registrations.map((registration) => registration.unregister())),
      )
  : Promise.resolve();
const institutionalAssets = Promise.all(
  [
    'assets/assets/images/baker-campus.webp',
    'assets/assets/branding/baker-mark.png',
  ].map(
    (source) =>
      new Promise((resolve) => {
        const image = new Image();
        image.onload = resolve;
        image.onerror = resolve;
        image.src = source;
      }),
  ),
);

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    await legacyWorkerCleanup;
    const appRunner = await engineInitializer.initializeEngine();
    await Promise.race([
      institutionalAssets,
      new Promise((resolve) => window.setTimeout(resolve, 2500)),
    ]);
    window.addEventListener(
      'flutter-first-frame',
      () => loading?.remove(),
      { once: true },
    );
    await appRunner.runApp();
    window.setTimeout(() => loading?.remove(), 5000);
  },
});
