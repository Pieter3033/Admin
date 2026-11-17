/* Presentation helpers only: native forms retain their existing SQLPage actions. */
(() => {
  "use strict";
  if (!document.documentElement.classList.contains("admin-portal")) return;

  const activePage = location.pathname.split("/").pop().toLowerCase();
  document.querySelectorAll("#sqlpage_header .nav-link[href]").forEach((link) => {
    const linkedPage = new URL(link.href).pathname.split("/").pop().toLowerCase();
    const usersPage = Boolean(document.querySelector(".admin-tabs"));
    if (linkedPage === activePage || (usersPage && linkedPage === "admin.sql")) {
      link.setAttribute("aria-current", "page");
    }
  });

  document.querySelectorAll(".admin-editor form").forEach((form) => {
    const clear = document.createElement("button");
    clear.type = "reset";
    clear.className = "btn admin-clear";
    clear.textContent = form.id === "admin-user-type-form" ? "Reset changes" : "Clear form";
    form.querySelector("fieldset").append(clear);

    form.querySelectorAll('input[type="password"]').forEach((input) => {
      const wrapper = document.createElement("span");
      wrapper.className = "admin-password-field";
      input.before(wrapper);
      wrapper.append(input);
      const toggle = document.createElement("button");
      toggle.type = "button";
      toggle.className = "admin-password-toggle";
      toggle.textContent = "Show";
      toggle.setAttribute("aria-label", "Show password");
      toggle.setAttribute("aria-pressed", "false");
      toggle.addEventListener("click", () => {
        const show = input.type === "password";
        input.type = show ? "text" : "password";
        toggle.textContent = show ? "Hide" : "Show";
        toggle.setAttribute("aria-label", show ? "Hide password" : "Show password");
        toggle.setAttribute("aria-pressed", String(show));
      });
      // The toggle lives inside the field's label; prevent its click from focusing the input.
      toggle.addEventListener("click", (event) => event.preventDefault());
      form.addEventListener("reset", () => {
        input.type = "password";
        toggle.textContent = "Show";
        toggle.setAttribute("aria-label", "Show password");
        toggle.setAttribute("aria-pressed", "false");
      });
      wrapper.append(toggle);
    });
  });

  const userPicker = document.querySelector("#admin-user-picker");
  userPicker?.querySelector('select[name="user_id"]')?.addEventListener("change", () => {
    if (userPicker.checkValidity()) userPicker.requestSubmit();
  });

  document.querySelectorAll('.admin-editor form').forEach((userForm) => {
    const userType = userForm.querySelector('select[name="user_type"]');
    const groundTeam = userForm.querySelector('select[name="dispatch_team_code"]');
    if (userType && groundTeam) {
      const teamLabel = groundTeam.closest("label");
      const requiredMark = document.createElement("span");
      requiredMark.className = "text-danger ms-1";
      requiredMark.textContent = "*";
      requiredMark.setAttribute("aria-label", "required");
      requiredMark.setAttribute("title", "required");
      groundTeam.before(requiredMark);

      const updateGroundTeam = () => {
        const isGroundTeam = userType.value === "11";
        groundTeam.required = isGroundTeam;
        groundTeam.disabled = !isGroundTeam;
        if (teamLabel) teamLabel.hidden = !isGroundTeam;
        requiredMark.hidden = !isGroundTeam;
        if (!isGroundTeam) groundTeam.value = "";
      };
      userType.addEventListener("change", updateGroundTeam);
      userForm.addEventListener("reset", () => queueMicrotask(updateGroundTeam));
      window.addEventListener("pageshow", updateGroundTeam);
      updateGroundTeam();
    }
  });

  document.querySelectorAll(".admin-directory, .admin-section").forEach((section) => {
    const search = section.querySelector('input[type="search"]');
    if (search) {
      const label = section.classList.contains("admin-directory") ? "Search users" : "Search records";
      search.setAttribute("aria-label", label);
      search.placeholder = label === "Search users" ? "Search name, username or role…" : "Search records…";
      // SQLPage's table filter listens for keyup; also cover paste and the native clear control.
      search.addEventListener("input", () => {
        search.dispatchEvent(new KeyboardEvent("keyup", { bubbles: true }));
      });
    }
  });

  const directory = document.querySelector(".admin-directory table");
  if (!directory) return;
  const headers = Array.from(directory.querySelectorAll("thead th"));
  const roleIndex = headers.findIndex((header) => header.textContent.trim() === "User Type");
  const usernameField = document.querySelector('input[name="del_username"], input[name="pass_reset_username"]');

  directory.querySelectorAll("tbody tr").forEach((row) => {
    const cells = row.querySelectorAll("td");
    if (cells.length !== headers.length || cells.length < 2) return;
    if (roleIndex >= 0 && cells[roleIndex].textContent.trim()) {
      const role = cells[roleIndex].textContent.trim();
      const badge = document.createElement("span");
      badge.className = "admin-role";
      badge.dataset.role = role;
      badge.textContent = role;
      cells[roleIndex].replaceChildren(badge);
    }
    const username = cells[0].textContent.trim();
    const user = document.createElement(usernameField ? "button" : "span");
    user.className = usernameField ? "admin-user admin-user-select" : "admin-user";
    const avatar = document.createElement("span");
    avatar.className = "admin-user-avatar";
    avatar.setAttribute("aria-hidden", "true");
    avatar.textContent = username.slice(0, 1).toUpperCase();
    const name = document.createElement("span");
    name.textContent = username;
    user.append(avatar, name);
    if (usernameField) {
      user.type = "button";
      user.setAttribute("aria-label", `Use username ${username}`);
      user.addEventListener("click", () => {
        usernameField.value = username;
        usernameField.dispatchEvent(new Event("input", { bubbles: true }));
        usernameField.focus();
      });
    }
    cells[0].replaceChildren(user);
  });
})();
