{{flutter_js}}
{{flutter_build_config}}

// Motor CanvasKit (Skia) para melhor desempenho na web (organograma, animações).
_flutter.loader.load({
  config: {
    renderer: 'canvaskit',
  },
});
