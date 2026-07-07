(() => {
	const BRAND_NAME = 'Indieark Chat';
	const OPEN_WEBUI = 'Open WebUI';
	let isPatching = false;
	let patchQueued = false;

	const normalizeBrandText = (value) => {
		if (!value) {
			return value;
		}

		return value
			.replace(/Indieark Chat\s*\(Open WebUI\)/g, BRAND_NAME)
			.replace(/Open WebUI/g, BRAND_NAME);
	};

	const setOrCreateMeta = (selector, attrs) => {
		let element = document.head.querySelector(selector);
		if (!element) {
			element = document.createElement('meta');
			document.head.appendChild(element);
		}

		Object.entries(attrs).forEach(([key, value]) => {
			element.setAttribute(key, value);
		});
	};

	const patchHead = () => {
		if (document.title) {
			const nextTitle = normalizeBrandText(document.title);
			if (nextTitle !== document.title) {
				document.title = nextTitle;
			}
		}

		setOrCreateMeta('meta[name="apple-mobile-web-app-title"]', {
			name: 'apple-mobile-web-app-title',
			content: BRAND_NAME
		});
		setOrCreateMeta('meta[name="application-name"]', {
			name: 'application-name',
			content: BRAND_NAME
		});
		setOrCreateMeta('meta[name="description"]', {
			name: 'description',
			content: BRAND_NAME
		});

		const metaThemeColor = document.head.querySelector('meta[name="theme-color"]');
		if (metaThemeColor) {
			metaThemeColor.setAttribute(
				'content',
				document.documentElement.classList.contains('light') ? '#f8f9fa' : '#0b0f19'
			);
		}

		document.head.querySelectorAll('[content], [title]').forEach((element) => {
			['content', 'title'].forEach((attr) => {
				const value = element.getAttribute(attr);
				const nextValue = normalizeBrandText(value);
				if (nextValue !== value) {
					element.setAttribute(attr, nextValue);
				}
			});
		});
	};

	const patchThemeClass = () => {
		document.documentElement.classList.toggle(
			'indieark-oled-dark',
			window.localStorage?.theme === 'oled-dark'
		);
	};

	const patchTextNode = (node) => {
		const value = node.nodeValue;
		const nextValue = normalizeBrandText(value);
		if (nextValue !== value) {
			node.nodeValue = nextValue;
		}
	};

	const patchBodyText = () => {
		if (!document.body) {
			return;
		}

		const sidebarName = document.getElementById('sidebar-webui-name');
		if (sidebarName && sidebarName.textContent !== BRAND_NAME) {
			sidebarName.textContent = BRAND_NAME;
		}

		const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
			acceptNode: (node) => {
				if (!node.nodeValue || !node.nodeValue.includes(OPEN_WEBUI)) {
					return NodeFilter.FILTER_REJECT;
				}

				const parent = node.parentElement;
				if (!parent || ['SCRIPT', 'STYLE', 'TEXTAREA', 'INPUT'].includes(parent.tagName)) {
					return NodeFilter.FILTER_REJECT;
				}

				return NodeFilter.FILTER_ACCEPT;
			}
		});

		const nodes = [];
		while (walker.nextNode()) {
			nodes.push(walker.currentNode);
		}
		nodes.forEach(patchTextNode);
	};

	const patchAll = () => {
		if (isPatching) {
			return;
		}

		isPatching = true;
		try {
			patchThemeClass();
			patchHead();
			patchBodyText();
		} finally {
			isPatching = false;
		}
	};

	const schedulePatch = () => {
		if (patchQueued) {
			return;
		}

		patchQueued = true;
		window.requestAnimationFrame(() => {
			patchQueued = false;
			patchAll();
		});
	};

	patchAll();
	document.addEventListener('DOMContentLoaded', patchAll, { once: true });
	window.addEventListener('storage', schedulePatch);

	new MutationObserver(schedulePatch).observe(document.documentElement, {
		childList: true,
		subtree: true,
		characterData: true,
		attributes: true,
		attributeFilter: ['class', 'content', 'title']
	});
})();
