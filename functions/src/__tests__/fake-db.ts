// In-memory RTDB mock — enough of the admin.database() surface for the pure
// *Core functions: ref().get()/set()/update()/push() and
// ref().orderByChild().equalTo().get(). Shared by the unit test suites.

export function makeSnap(val: unknown) {
  return {
    val: () => (val === undefined ? null : val),
    exists: () => val !== null && val !== undefined,
  };
}

export class FakeDb {
  store: Record<string, unknown> = {};
  private counter = 0;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private get(path: string): any {
    const parts = path.split("/").filter(Boolean);
    let node: unknown = this.store;
    for (const p of parts) {
      if (node === null || typeof node !== "object") return undefined;
      node = (node as Record<string, unknown>)[p];
    }
    return node;
  }

  private set(path: string, value: unknown): void {
    const parts = path.split("/").filter(Boolean);
    let node = this.store as Record<string, unknown>;
    for (let i = 0; i < parts.length - 1; i++) {
      const p = parts[i];
      if (typeof node[p] !== "object" || node[p] === null) node[p] = {};
      node = node[p] as Record<string, unknown>;
    }
    node[parts[parts.length - 1]] = value;
  }

  private remove(path: string): void {
    const parts = path.split("/").filter(Boolean);
    let node = this.store as Record<string, unknown>;
    for (let i = 0; i < parts.length - 1; i++) {
      const p = parts[i];
      if (typeof node[p] !== "object" || node[p] === null) return;
      node = node[p] as Record<string, unknown>;
    }
    delete node[parts[parts.length - 1]];
  }

  ref(path: string) {
    const self = this;
    const refObj = {
      child: (sub: string) => self.ref(path + "/" + sub),
      get: async () => makeSnap(self.get(path)),
      set: async (value: unknown) => self.set(path, value),
      remove: async () => self.remove(path),
      update: async (value: Record<string, unknown>) => {
        const current = (self.get(path) as Record<string, unknown>) ?? {};
        self.set(path, {...current, ...value});
      },
      push: () => {
        const key = `gen-${++self.counter}`;
        const childPath = `${path}/${key}`;
        return {
          key,
          set: async (value: unknown) => self.set(childPath, value),
          update: async (value: Record<string, unknown>) => {
            const current =
              (self.get(childPath) as Record<string, unknown>) ?? {};
            self.set(childPath, {...current, ...value});
          },
        };
      },
      transaction: async (updater: (current: unknown) => unknown) => {
        const current = self.get(path) ?? null;
        const next = updater(current);
        // RTDB semantics: returning undefined aborts the transaction.
        if (next === undefined) {
          return {committed: false, snapshot: makeSnap(current)};
        }
        self.set(path, next);
        return {committed: true, snapshot: makeSnap(next)};
      },
      orderByChild: (field: string) => ({
        equalTo: (value: unknown) => ({
          get: async () => {
            const all =
              (self.get(path) as Record<string, Record<string, unknown>>) ?? {};
            const filtered: Record<string, unknown> = {};
            for (const [k, v] of Object.entries(all)) {
              if (v && (v as Record<string, unknown>)[field] === value) {
                filtered[k] = v;
              }
            }
            return makeSnap(Object.keys(filtered).length ? filtered : null);
          },
        }),
      }),
    };
    return refObj;
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function db(seed: Record<string, unknown> = {}): any {
  const d = new FakeDb();
  d.store = JSON.parse(JSON.stringify(seed));
  return d;
}

export async function expectHttpsError(promise: Promise<unknown>, code: string) {
  await expect(promise).rejects.toMatchObject({code});
}
