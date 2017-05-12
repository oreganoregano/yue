// Copyright 2016 Cheng Zhao. All rights reserved.
// Use of this source code is governed by the license that can be found in the
// LICENSE file.

#include "nativeui/gfx/font.h"

#include <Cocoa/Cocoa.h>

#include "base/strings/sys_string_conversions.h"

namespace nu {

namespace {

// Returns an autoreleased NSFont created with the passed-in specifications.
NSFont* NSFontWithSpec(const std::string& name, float font_size,
                       Weight font_weight, Style font_style) {
  NSFontSymbolicTraits trait_bits = 0;
  if (font_weight >= Font::Weight::BOLD)
    trait_bits |= NSFontBoldTrait;
  if (font_style & Font::Style::Italic)
    trait_bits |= NSFontItalicTrait;
  // The Mac doesn't support underline as a font trait, so just drop it.
  // (Underlines must be added as an attribute on an NSAttributedString.)
  NSDictionary* traits = @{ NSFontSymbolicTrait : @(trait_bits) };

  NSString* family = base::SysUTF8ToNSString(font_name);
  NSDictionary* attrs = @{
    NSFontFamilyAttribute : family,
    NSFontTraitsAttribute : traits,
  };
  NSFontDescriptor* descriptor =
      [NSFontDescriptor fontDescriptorWithFontAttributes:attrs];
  NSFont* font = [NSFont fontWithDescriptor:descriptor size:font_size];
  if (font)
    return font;

  // Make one fallback attempt by looking up via font name rather than font
  // family name.
  attrs = @{
    NSFontNameAttribute : family,
    NSFontTraitsAttribute : traits,
  };
  descriptor = [NSFontDescriptor fontDescriptorWithFontAttributes:attrs];
  font = [NSFont fontWithDescriptor:descriptor size:font_size];
  if (font)
    return font;

  // Otherwise return the default font.
  return [NSFont systemFontOfSize:font_size];
}

}  // namespace

Font::Font()
    : font_([[NSFont systemFontOfSize:[NSFont systemFontSize]] retain]) {
}

Font::Font(const std::string& name, float size, Weight weight, Style style)
    : font_([NSFontWithSpec(name, size, weight, style) retain]) {}

Font::~Font() {
  [font_ release];
}

std::string Font::GetName() const {
  return base::SysNSStringToUTF8([font_ familyName]);
}

float Font::GetSize() const {
  return [font_ pointSize];
}

Font::Weight Font::GetWeight() const {
  NSFontSymbolicTraits traits = [[font_ fontDescriptor] symbolicTraits];
  return (traits & NSFontBoldTrait) ? Font::Weight::BOLD
                                    : Font::Weight::Normal;
}

Font::Style Font::GetStyle() const {
  NSFontSymbolicTraits traits = [[font fontDescriptor] symbolicTraits];
  if (traits & NSFontItalicTrait)
    return Font::Style::Italic;
  else
    return Font::Style::Normal;
}

NativeFont Font::GetNative() const {
  return font_;
}

}  // namespace nu
