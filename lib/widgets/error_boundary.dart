import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';

class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.fallback,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error, StackTrace stackTrace)? fallback;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();

    // Set up global error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorHandler.handleFlutterError(details);
      if (mounted && _isFatal(details.exception)) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
    };
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.fallback != null) {
        return widget.fallback!(_error!, _stackTrace!);
      }

      return _DefaultErrorWidget(
        error: _error!,
        stackTrace: _stackTrace!,
        onRetry: _resetError,
      );
    }

    return ErrorBoundaryWrapper(
      onError: (error, stackTrace) {
        widget.onError?.call(error, stackTrace);
        Logger.exception('Error Boundary', error, stackTrace);

        if (mounted && _isFatal(error)) {
          setState(() {
            _error = error;
            _stackTrace = stackTrace;
          });
        }
      },
      child: widget.child,
    );
  }

  // Flutter reports some purely cosmetic, debug-mode-only layout warnings
  // (e.g. an overflowing Row/Column, or a rebuild scheduled mid-frame)
  // through the same FlutterError.onError channel as genuine crashes.
  // Those are already visually indicated (the yellow/black stripes) and
  // never affect release builds, so treating them as fatal here would
  // replace the whole screen with an error page over what is, from the
  // user's perspective, a minor visual glitch. Only escalate to the
  // full-screen fallback for errors that aren't one of these known
  // non-fatal, debug-only warnings.
  static bool _isFatal(Object error) {
    final message = error.toString();
    const nonFatalPatterns = [
      'A RenderFlex overflowed',
      'A RenderFlow overflowed',
      'Build scheduled during frame',
    ];
    return !nonFatalPatterns.any(message.contains);
  }
}

class ErrorBoundaryWrapper extends StatefulWidget {
  const ErrorBoundaryWrapper({
    super.key,
    required this.child,
    required this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  State<ErrorBoundaryWrapper> createState() => _ErrorBoundaryWrapperState();
}

class _ErrorBoundaryWrapperState extends State<ErrorBoundaryWrapper> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Catch errors in the widget tree
    FlutterError.onError = (FlutterErrorDetails details) {
      // Replacing the default handler drops Flutter's report, which names the
      // widget behind errors like overflows. Keep it while debugging.
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      widget.onError(details.exception, details.stack ?? StackTrace.current);
    };
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({
    required this.error,
    required this.stackTrace,
    required this.onRetry,
  });

  final Object error;
  final StackTrace stackTrace;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We apologize for the inconvenience. The error has been logged and we\'re working to fix it.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (AppConfig.isDevelopment) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error Details:',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            error.toString(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Stack Trace:',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            stackTrace.toString(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Try Again'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Global error handler for uncaught async errors
class GlobalErrorHandler {
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorHandler.handleFlutterError(details);
    };

    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorHandler.handleAsyncError(error, stack);
      return true;
    };
  }
}

// Widget to catch and handle specific errors in parts of the app
class SafeWidget extends StatelessWidget {
  const SafeWidget({
    super.key,
    required this.child,
    this.onError,
    this.fallback,
    this.errorMessage,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget? fallback;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: onError,
      fallback: fallback != null
          ? (error, stackTrace) => fallback!
          : (error, stackTrace) => _SafeErrorWidget(
              message: errorMessage ?? 'Something went wrong in this section',
              error: error,
              isDevelopment: AppConfig.isDevelopment,
            ),
      child: child,
    );
  }
}

class _SafeErrorWidget extends StatelessWidget {
  const _SafeErrorWidget({
    required this.message,
    required this.error,
    required this.isDevelopment,
  });

  final String message;
  final Object error;
  final bool isDevelopment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          if (isDevelopment) ...[
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Theme.of(
                  context,
                ).colorScheme.onErrorContainer.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
