{
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
        document.body.setAttribute("data-theme", theme);
        break;
      default:
        document.body.setAttribute("data-theme", userAuto);
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
