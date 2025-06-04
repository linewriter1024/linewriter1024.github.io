{
  // This method courtesy of ChatGPT and its training data.
  (function replaceDarkModeMediaRule() {
    for (const sheet of document.styleSheets) {
      try {
        const rules = sheet.cssRules || sheet.rules;
        for (let i = 0; i < rules.length; i++) {
          const rule = rules[i];

          // Check for @media (prefers-color-scheme: dark)
          if (
            rule instanceof CSSMediaRule &&
            rule.conditionText.trim() === '(prefers-color-scheme: dark)'
          ) {
            const newRules = [];

            // Convert all rules inside media into scoped rules under html[data-theme="dark"]
            for (const innerRule of rule.cssRules) {
              const scopedSelector = innerRule.selectorText
                .split(',')
                .map(sel => `html[data-theme="dark"] ${sel.trim()}`)
                .join(', ');
              const cssText = `${scopedSelector} { ${innerRule.style.cssText} }`;
              newRules.push(cssText);
            }

            // Remove the original media rule
            sheet.deleteRule(i);

            // Insert new scoped rules
            for (const newRuleText of newRules) {
              sheet.insertRule(newRuleText, sheet.cssRules.length);
            }

            // Exit after handling the first match
            return;
          }
        }
      } catch (e) {
        // Some styleSheets may be cross-origin and not accessible
        console.warn("Couldn't access stylesheet:", e);
      }
    }
  })();

  const lightSelector = document.createElement("select");
  lightSelector.innerHTML = `
        <option value="">Auto</option>
        <option value="dark">Dark</option>
        <option value="light">Light</option>
    `;
  lightSelector.setAttribute("id", "light-selector");
  document.currentScript.parentNode.insertBefore(
    lightSelector,
    document.currentScript
  );

  const theme = localStorage.getItem("theme");
  lightSelector.value = theme || "";

  let userAuto = "light";

  const applyTheme = () => {
    const theme = lightSelector.value;
    switch (theme) {
      case "light":
      case "dark":
        document.body.parentNode.setAttribute("data-theme", theme);
        break;
      default:
        document.body.parentNode.setAttribute("data-theme", userAuto);
        break;
    }
  };

  const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)");
  prefersDarkScheme.addEventListener("change", (event) => {
    if (event.matches) {
      userAuto = "dark";
    } else {
      userAuto = "light";
    }

    applyTheme();
  });

  if (prefersDarkScheme.matches) {
    userAuto = "dark";
  } else {
    userAuto = "light";
  }

  lightSelector.onchange = () => {
    localStorage.setItem("theme", lightSelector.value);
    applyTheme();
  };

  applyTheme();
}
