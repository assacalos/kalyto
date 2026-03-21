import 'package:flutter/material.dart';
import 'package:easyconnect/utils/responsive_helper.dart';

/// Widget qui adapte son contenu selon la taille d'écran
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getHorizontalPadding(context),
            vertical: ResponsiveHelper.getVerticalPadding(context),
          ),
      constraints:
          maxWidth != null
              ? BoxConstraints(maxWidth: maxWidth!)
              : BoxConstraints(
                maxWidth: ResponsiveHelper.getMaxContentWidth(context),
              ),
      child: child,
    );
  }
}

/// Widget qui affiche différents contenus selon la taille d'écran
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveHelper.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Widget qui crée une grille responsive
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
        childAspectRatio:
            childAspectRatio ??
            ResponsiveHelper.getGridChildAspectRatio(context),
        crossAxisSpacing:
            crossAxisSpacing ?? ResponsiveHelper.getSpacing(context),
        mainAxisSpacing:
            mainAxisSpacing ?? ResponsiveHelper.getSpacing(context),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Widget qui crée une liste responsive avec scroll
class ResponsiveScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const ResponsiveScrollView({
    super.key,
    required this.child,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getHorizontalPadding(context),
            vertical: ResponsiveHelper.getVerticalPadding(context),
          ),
      child: child,
    );
  }
}

/// Widget qui crée une ligne responsive (Row qui devient Column sur mobile)
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? spacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final spacingValue = spacing ?? ResponsiveHelper.getSpacing(context);

    if (ResponsiveHelper.isMobile(context)) {
      // Sur mobile, afficher en colonne
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children:
            children
                .expand((child) => [child, SizedBox(height: spacingValue)])
                .take(children.length * 2 - 1)
                .toList(),
      );
    }

    // Sur tablette et desktop, afficher en ligne
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children:
          children
              .expand((child) => [child, SizedBox(width: spacingValue)])
              .take(children.length * 2 - 1)
              .toList(),
    );
  }
}

/// Widget qui crée un texte responsive
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    final fontSize = ResponsiveHelper.getFontSize(
      context,
      mobile: baseStyle.fontSize ?? 14.0,
      tablet: (baseStyle.fontSize ?? 14.0) * 1.1,
      desktop: (baseStyle.fontSize ?? 14.0) * 1.2,
    );

    return Text(
      text,
      style: baseStyle.copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }
}

/// Widget qui crée une carte responsive
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2.0,
      color: color,
      child: Padding(
        padding:
            padding ?? EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
        child: child,
      ),
    );
  }
}

/// Widget qui crée un espacement responsive
class ResponsiveSpacing extends StatelessWidget {
  final double? height;
  final double? width;

  const ResponsiveSpacing({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getSpacing(context);
    return SizedBox(height: height ?? spacing, width: width ?? spacing);
  }
}
